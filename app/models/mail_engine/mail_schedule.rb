# == Schema Information
#
# Table name: mail_schedules
#
#  id               :integer         not null, primary key
#  name             :string(255)
#  mail_template_id :integer
#  user_group       :string(255)
#  count            :integer         default(0)
#  sent_count       :integer         default(0)
#  period           :string(255)
#  payload          :string(255)
#  first_send_at    :datetime
#  last_sent_at     :datetime
#  created_at       :datetime
#  updated_at       :datetime
#  default_locale   :string
#

class MailEngine::MissingMailTemplate < StandardError; end

class MailEngine::MailSchedule < ActiveRecord::Base
  validates_presence_of :name, :user_group, :mail_template_id, :period, :count, :first_send_at
  validates_inclusion_of :period, :in => %w( once daily weekly monthly yearly), :message => "period should in 'daily', 'weekly' and 'monthly'"
  belongs_to :mail_template
  scope :available, where("(sent_count < count OR count = 0) AND available=?", true)

  PERIOD_TO_UNIT_TABLE = {
    "daily" => ["day", 1],
    "weekly" => ["week", 7],
    "monthly" => ["month", 30],
    "yearly" => ["year", 365]
  }

  # will return an array like
  #
  #   [
  #     [MailSchedule#xxx, 2010-01-01 20:15],
  #     [MailSchedule#xxx, 2010-01-01 20:15]
  #   ]
  #
  def self.future_schedules(schedule_count = 5)
    schedule_count = 5 if schedule_count < 5
    all_future_schedules = []
    MailEngine::MailSchedule.available.all.each do |schedule|
      next_schedules = [schedule].product(schedule.next_several_schedule_dates(schedule_count))
      all_future_schedules += next_schedules if next_schedules.present?
    end
    # sort by date
    all_future_schedules.sort{|x,y| x[1] <=> y[1]}.slice(1..schedule_count)
  end

  # FIXME monthly will has some problem due to each month is not exact 30 days.
  # this func will return an array of date.
  def next_several_schedule_dates(schedule_count = 5)
    # check if send count reached the top limit count.
    return [] if (sent_count >= count and count != 0)
    # only send once.
    if period == 'once'
      # check if it is still available.
      if first_send_at > Time.now
        return [first_send_at]
      else
        return []
     end
    end

    # other periods
    rest_count = (count == 0 ? schedule_count : count - sent_count)
    (1..rest_count).map do |i|
      last_schedule_time + i.send(PERIOD_TO_UNIT_TABLE[period].first)
    end
  end

  # if a weekly schedule, first send at last monday, and today is tuesday, so the last schedule time should be this monday
  # if a weekly schedule, first send at next monday, and today is tuesday, so the last schedule time should be the first_send_at
  def last_schedule_time
    period_unit    = PERIOD_TO_UNIT_TABLE[period].first
    period_days    = PERIOD_TO_UNIT_TABLE[period].last
    if first_send_at.past?
      days_past = ((Time.now - first_send_at)/(3600*24)).round
      periods_past = days_past / period_days
      first_send_at + periods_past * 1.send(period_unit)
    else
      first_send_at
    end
  end

  # list mail log with the same mail_template_path to current mail_template's path
  def logs(count = 10)
    MailEngine::MailLog.where(:mail_template_path => self.mail_template.actual_path).order("id desc").limit(count)
  end

  # load user info into payload hash used at mail template.
  def load_payload user
    payload_hash = {}
    self.payload.split(",").each do |col|
      payload_hash[col] = user.send(col)
    end
    payload_hash
  end

  # send test mail to specific recipient email address, with loading sample_user's data.
  def send_test_mail_to!(recipient, sample_user_id)
    raise "Wrong email format." if recipient.blank? or recipient !~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    sample_user = MailEngine::USER_MODEL.find(sample_user_id)

    I18n.with_locale(mail_template.locale) do
      MailEngine::MailDispatcher.send( mail_template.template_name.to_sym, :to => recipient, :values => self.load_payload(sample_user) ).deliver
    end
  end

  # If execute sendmail twice very soon(within 14 minutes), it should not be able to send mail again.
  def ready_to_send?
    # check if send count reached the total count.
    return false if (sent_count >= count and count != 0)
    # only send once.
    return sent_count < 1 if period == 'once'

    ###  ready for first send?
    # why 15 minutes?   because crontab will run each 15 minutes.
    timespan_since_last_mail = (Time.now.to_i - last_sent_at.to_i).abs
    timespan_to_first_send_at = (Time.now.to_i - first_send_at.to_i).abs
    not_sent_mail_within_15_minutes = last_sent_at.nil? || (timespan_since_last_mail >= 60*15)
    start_first_send_within_15_minutes = (timespan_to_first_send_at < 60*15)

    # cycle start
    cycle_start = case period
                       when 'daily'
                         1.days.ago.to_i <= last_sent_at.to_i
                       when 'weekly'
                         1.week.ago.to_i <= last_sent_at.to_i
                       when 'monthly'
                         1.month.ago.to_i <= last_sent_at.to_i
                       else
                         false
                       end
    not_sent_mail_within_15_minutes and (cycle_start or start_first_send_within_15_minutes)
  end

  # used in Rake task, the main mail sending method.
  def sendmail
    puts "---> Schedule: '#{self.name}'" if Rails.env != 'test'
    return false unless ready_to_send? # puts "---> not ready"

    MailEngine::USER_MODEL.send(self.user_group.to_sym).each do |user|
      puts "-> sending mail to #{user.email}" if Rails.env != 'test'
      ### FIXME user.email, what if user don't have email column.
      user_locale = begin
                      user.send(MailEngine::Base.current_config["user_locale_column"])
                    rescue
                      I18n.default_locale
                    end

      begin
        # when there is default_locale been set, should fallback to default_locale template, when can't find the locale user in user settings.
        if !mail_template.existed_variations.map(&:locale).include?(user_locale)
          if self.default_locale.present?
            raise MailEngine::MissingMailTemplate.new("not found template for user locale: #{user_locale}")
          else
            raise "skip sending mail since not found correspond locale template."
          end
        end

        I18n.with_locale user_locale do
          MailEngine::MailDispatcher.send(mail_template.template_name.to_sym, :to => user.email, :values => self.load_payload(user) ).deliver
        end
      rescue MailEngine::MissingMailTemplate
        I18n.with_locale self.default_locale do
          MailEngine::MailDispatcher.send(mail_template.template_name.to_sym, :to => user.email, :values => self.load_payload(user) ).deliver
        end
      rescue
        # do nothing, just don't sent mail.
      end
    end

    self.update_attributes :last_sent_at => Time.now, :sent_count => self.sent_count + 1
  end
end