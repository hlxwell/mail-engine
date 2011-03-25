require 'test_helper'

class MailEngine::MailScheduleTest < ActiveSupport::TestCase

  context "schedule with 2 locale users" do
    setup do
      User.destroy_all
      ActionMailer::Base.deliveries.clear

      @user_en = FactoryGirl.create(:user, :locale => 'en')
      @user_zh = FactoryGirl.create(:user, :email => "mmm@gmail.com", :locale => 'zh')
      @schedule = FactoryGirl.create(:mail_schedule, :period => "once")
      @en_template = @schedule.mail_template
    end

    should "send correct language mail template to user" do
      zh_template = FactoryGirl.create(:marketing_mail_template, :body => "chinese marketing template", :locale => "zh")

      assert_equal 2, MailEngine::MailTemplate.count
      assert @schedule.ready_to_send?
      assert_equal 0, ActionMailer::Base.deliveries.size
      @schedule.sendmail
      assert_equal 2, ActionMailer::Base.deliveries.size
      assert ActionMailer::Base.deliveries.first.body.raw_source.include?(@en_template.body)
      assert ActionMailer::Base.deliveries.last.body.raw_source.include?(zh_template.body)
    end

    should "not send mail without correct template and default template" do
      @schedule.sendmail
      assert_equal 1, ActionMailer::Base.deliveries.size
    end

    should "send mail without correct template but has set default template" do
      @schedule.default_locale = 'en'
      @schedule.sendmail
      assert_equal 2, ActionMailer::Base.deliveries.size
      assert ActionMailer::Base.deliveries.last.body.raw_source.include?(@en_template.body)
    end
  end

  context "schedule" do
    setup do
      @user = FactoryGirl.create(:user)
      @schedule = FactoryGirl.create(:mail_schedule, :period => "once")
    end

    should "have logs" do
      @schedule.send_test_mail_to!("hlxwell@gmail.com", @user.id)
      assert_equal 1, @schedule.logs.count
    end

    should "be able to load all payload" do
      assert_equal @schedule.load_payload(@user), {"lastname" => "He", "firstname" => "Michael"}
    end

    should "check email when send_test_mail_to" do
      assert_raise RuntimeError do
        @schedule.send_test_mail_to!("hlxwell", @user.id)
      end
    end

    should "be able to send_test_mail_to" do
      @schedule.send_test_mail_to!("hlxwell@gmail.com", @user.id)
      assert_equal 1, MailEngine::MailLog.count
    end

    should "check sample user when send_test_mail_to" do
      assert_raise ActiveRecord::RecordNotFound do
        @schedule.send_test_mail_to!("hlxwell@gmail.com", 0)
      end
    end

    context "when get next_several_schedules" do
      setup do
        @schedule.first_send_at = 2.days.ago
      end

      should "get correct list for once schedule" do
        @schedule.sent_count = 1
        assert_equal [], @schedule.next_several_schedule_dates

        @schedule.sent_count = 0
        assert_equal [], @schedule.next_several_schedule_dates
      end

      should "get correct list for daily schedule" do
        @schedule.period = "daily"
        assert_equal Time.now.tomorrow.day, @schedule.next_several_schedule_dates.first.day
      end

      should "get correct list for weekly schedule" do
        @schedule.period = "weekly"
        assert_equal (@schedule.first_send_at + 1.week).day, @schedule.next_several_schedule_dates.first.day
      end

      should "get correct list for monthly schedule" do
        @schedule.period = "monthly"
        assert_equal (@schedule.first_send_at + 1.month).day, @schedule.next_several_schedule_dates.first.day
      end

      should "get correct list for yearly schedule" do
        @schedule.period = "yearly"
        assert_equal (@schedule.first_send_at + 1.year).day, @schedule.next_several_schedule_dates.first.day
      end
    end
  end

  context "once sending only schedule" do
    setup do
      clear_database
      @schedule = FactoryGirl.create(:mail_schedule, :period => "once")
    end

    should "send mail only once" do
      assert @schedule.ready_to_send?
      @schedule.sendmail
      assert_equal 1, @schedule.sent_count
      # should not be able to send anyway
      assert !@schedule.ready_to_send?
      Timecop.travel(1.year.since)
      assert !@schedule.ready_to_send?
    end
  end

  context "daily schedule" do
    setup do
      clear_database
      @schedule = FactoryGirl.create(:mail_schedule, :period => "daily")
    end

    should "send mail every day at the same time to first_send_at" do
      assert @schedule.ready_to_send?
      @schedule.sendmail
      assert !@schedule.ready_to_send?
      Timecop.travel(1.day.since)

      assert @schedule.ready_to_send?
      @schedule.sendmail
      assert !@schedule.ready_to_send?
      Timecop.return
    end
  end

end