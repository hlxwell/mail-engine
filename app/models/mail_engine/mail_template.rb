# == Schema Information
#
# Table name: mail_templates
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  subject       :string(255)
#  path          :string(255)
#  format        :string(255)     default("html")
#  locale        :string(255)
#  handler       :string(255)     default("liquid")
#  body          :text
#  partial       :boolean         default(FALSE)
#  for_marketing :boolean         default(FALSE)
#  layout        :string(255)     default("none")
#  zip_file      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#
class MailEngine::MailTemplate < ActiveRecord::Base
  attr_accessor :create_by_upload

  mount_uploader :zip_file, MailEngine::ZipFileUploader

  validates :name, :path, :presence => true
  validates :subject, :presence => true, :if => Proc.new { |template| !template.partial? }
  validates :locale, :inclusion => I18n.available_locales.map(&:to_s)
  validates :format, :inclusion => Mime::SET.symbols.map(&:to_s)
  validates :layout, :presence => true, :if => Proc.new {|template| !template.partial? }
  validates :body, :presence => true, :if => Proc.new {|template| template.create_by_upload.blank? }
  validates :zip_file, :presence => true, :if => Proc.new {|template| template.create_by_upload.present? }
  validates :path, :format => { :with => /([^\/]+\/)+/i, :message => "path should looks like 'controller/action'" }, :if => Proc.new { |template| !template.for_marketing? }
  validates :path, :format => { :with => /^[a-z\_]+$/i, :message => "path should be consisted of english character and underscore." }, :if => Proc.new { |template| template.for_marketing? }
  # validates :handler, :inclusion => ActionView::Template::Handlers.extensions.map(&:to_s)
  validates_uniqueness_of :path, :scope => [:locale, :handler, :format, :partial]
  after_validation :check_placeholders_for_layout
  before_validation :check_zip_file, :if => Proc.new {|template| template.create_by_upload.present? }

  has_many :mail_schedules, :dependent => :nullify
  has_many :template_partials, :dependent => :destroy
  has_many :partials, :through => :template_partials
  has_many :mail_template_files
  # if self is partial, lookup back to mail templates.
  has_many :partial_users, :class_name => "TemplatePartial", :foreign_key => "partial_id"
  has_many :mail_templates, :through => :partial_users

  accepts_nested_attributes_for :template_partials, :allow_destroy => true

  scope :for_system, where(:for_marketing => false, :partial => false)
  scope :for_marketing, where(:for_marketing => true, :partial => false)
  scope :partial, where(:partial => true)
  scope :html, where(:format => 'html')
  scope :text, where(:format => 'text')

  after_create :process_zip_file
  before_save :delete_partials_if_new_partials_added
  after_save do
    # clear cached paths
    MailEngine::MailTemplateResolver.instance.clear_cache

    # update subject
    MailEngine::MailTemplate.update_all(["subject=?", self.subject], ["path = ? AND locale = ?", self.path, self.locale])
  end

  # class methods
  class << self
    # get subject from other templates with same path
    def get_subject_from_bother_template(path, locale, for_marketing)
      return nil if path.blank?
      MailEngine::MailTemplate.where(:path => path, :locale => locale, :for_marketing => for_marketing, :partial => false).select("subject").first.try(:subject)
    end

    # import all mail template from exist system.
    # format like: views/user_mailer/index.en.html.erb
    def import_from_files!(mailer_name)
      mailer = mailer_name.classify.constantize
      raise "not a mailer or doesn't provide mailer." unless mailer.ancestors.include?(ActionMailer::Base)

      # prepare data
      mailer_actions     = mailer.action_methods
      file_view_paths    = mailer.view_paths.select {|path| path.is_a?(ActionView::FileSystemResolver)}
      available_formats  = [:text, :html]
      available_handlers = [:erb, :liquid, :rhtml]
      available_locales  = I18n.available_locales

      # collect all possible combinations
      search_envs = file_view_paths.product(mailer_actions, available_formats, available_handlers, available_locales)

      # [#<ActionView::FileSystemResolver>, "notify_to_user", :text, :erb, :zh]
      search_envs.map { |resolver, action, format, handler, locale|
        template_files = resolver.find_all "#{mailer.to_s.underscore}/#{action}", {}, false, {
          :locale => Array.wrap(locale),
          :formats => Array.wrap(format),
          :handlers => Array.wrap(handler)
        }

        # file_path => app/views/user_mailer/notify.html.erb
        template_files.map do |file_path|
          template = MailEngine::MailTemplate.create(
            :name    => "#{mailer.to_s.underscore}/#{action} - #{format}",
            :subject => "#{mailer.to_s.underscore}/#{action} - #{format}",
            :path    => "#{mailer.to_s.underscore}/#{action}",
            :format  => format.to_s,
            :locale  => locale.to_s,
            :body    => File.read(file_path.identifier)
          )
        end
      }.compact.flatten.uniq # search_envs
    end

    def all_system_mailers
      mailer_path = File.join(Rails.root, "app", "mailers")
      mailers_found_on_system = `find #{mailer_path} -name *.rb`.split("\n")
      # remove mailer_path just show file names
      mailers_found_on_system.map {|mailer| mailer.sub(/^#{mailer_path}\//, '')}
    end
  end

  # detect if current partial template is used by other templates.
  def partial_in_use?
    self.partial? and self.mail_templates.count > 0
  end

  # list the templates with same path, but different locale and format
  def variations(for_partial = false)
    all_variation_codes = I18n.available_locales.product([:html, :text])
    current_existed_variations = existed_variations(for_partial)
    existed_variation_codes = current_existed_variations.map do |template|
                                [template.locale.to_sym, template.format.to_sym]
                              end
    missing_variations = (all_variation_codes - existed_variation_codes).map do |locale, format|
      MailEngine::MailTemplate.new :locale => locale.to_s, :format => format.to_s
    end

    missing_variations + current_existed_variations
  end

  def existed_variations for_partial = false
    self.class.where(:path => self.path, :partial => for_partial).order("locale, format")
  end

  def actual_path
    return "mail_engine/mail_dispatcher/#{self.path}" if self.for_marketing?
    self.path
  end

  # has_many :logs, :class_name => "MailEngine::MailLog", :conditions => {:mail_template_path => self.path}
  def logs
    MailEngine::MailLog.where(:mail_template_path => self.actual_path).order("id desc").limit(10)
  end

  # FIXME: if no changes just keep the same, it sill will remove the template partial and add a new one
  def delete_partials_if_new_partials_added
    if self.template_partials.detect {|tmp| !tmp.persisted? }.present? || self.layout == 'none' # has new partials selected
      MailEngine::TemplatePartial.destroy_all(:mail_template_id => self) # remove previous partials
    end
  end

  # if uploaded a zip file, check:
  # 1. only one html?
  # 2. has html
  def check_zip_file
    begin
      @extracted_files, @extraction_dir_path = MailEngine::ZipProcessor.extract_all_files(self.zip_file.path, %w{css jpg jpeg gif png html htm})

      if @extracted_files.present?
        MailEngine::HtmlDocumentAssetsReplacer.check! @extracted_files if @extracted_files.present?
      else
        raise "Extract zip file failed or not zip file."
      end
    rescue => e
      errors.add(:file, e.message)
    end
  end

  # FIXME: remove the hostname
  def process_zip_file(hostname = ActionMailer::Base.default_url_options[:host] || "localhost:3000")
    return if @extracted_files.blank?
    self.update_attribute :body, MailEngine::HtmlDocumentAssetsReplacer.process(self, @extracted_files, hostname)
    # remove the tmp files
    system("rm -rf #{@extraction_dir_path}")
  end

  def check_placeholders_for_layout
    return if self.partial?
    if self.template_partials.detect{ |tmp| !tmp.persisted? }.present? || self.layout == 'none'
      self.template_partials.delete_if { |tmp| tmp.persisted? }
    end

    names = self.template_partials.map(&:placeholder_name)

    case self.layout
    when "none"
      errors.add(:partials, "should have no partials") unless names.blank?
    when "only_footer"
      errors.add(:partials, "should have footer partial") unless names.include?('footer') and names.size == 1
    when "header_and_footer"
      errors.add(:partials, "should have header and footer partials") unless names.include?('header') and names.include?('footer') and names.size == 2
    else
    end
  end

  ["html", "text"].each do |method|
    define_method "#{method}?" do
      self.format == method
    end
  end

  def type
    return 'partial' if self.partial?
    return 'system' unless self.for_marketing?
    return 'marketing' if self.for_marketing?
  end

  # controller/action_name => for get the action_name
  def template_name
    self.path.scan(/[^\/]+$/).first
  end

  # prepend "_" at partial name.
  def filename
    tmp_path = self.path
    if self.partial
      tmp_path.gsub(/([^\/]+)\z/, '_\1')
    else
      tmp_path
    end
  end

  def full_path
    "#{filename}.#{self.locale}.#{self.format}.#{self.handler}"
  end

  # return one clone version of self with all duplicated relations.
  def duplicate merge_options = {}
    # start to clone
    duplicated_obj = self.clone :except => [:zip_file], :include => [:template_partials, :mail_template_files]
    duplicated_obj.zip_file = File.open(self.zip_file.path) if self.zip_file.path # it will make a copy version of zipfile
    duplicated_obj.attributes = merge_options if merge_options.is_a? Hash # merge custom options
    # without saving can't not create files. so save it first.
    duplicated_obj.save

    ### below code is used to clone mail_template_files and replace the new url for cloned template body.
    # pair the mail_template_files and insert into substitution_array.
    substitution_pair_array = []
    self.mail_template_files.each_with_index do |origin_file, index|
      substitution_pair_array << [origin_file, duplicated_obj.mail_template_files[index]]
    end

    # replace image or file url with new url.
    original_body = self.body

    substitution_pair_array.each do |origin_file, new_file|
      original_body = MailEngine::HtmlDocumentAssetsReplacer.replace_resource_in_html(
        original_body,
        origin_file.file.url,
        new_file.file.url,
        :url
      )
    end

    # write back the new body with cloned resource urls.
    duplicated_obj.update_attributes :body => original_body
    duplicated_obj
  end

  # def send_test_mail_to!(recipient)
  #   # raise "Wrong email format." if recipient.blank? or recipient !~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  #   raise "Can not find any user." if (sample_user = MailEngine::USER_MODEL.first).blank?
  #
  #   ### 3 conditions
  #   # 1. action - marketing mail only have one action
  #   # 2. controler/action
  #   # 3. namespace/namespace/controller/action
  #   #
  #   path_sections = self.path.split("/")
  #
  #   # marketing mail
  #   if self.for_marketing?
  #     action_name = path_sections.last
  #     mailer_class_name = "MailEngine::MailDispatcher"
  #   else
  #     mailer_name = path_sections[-2]
  #     action_name = path_sections[-1]
  #     namespaces = path_sections - Array.wrap(path_sections[-2..-1])
  #
  #     if namespaces.present?
  #       mailer_class_name = namespaces.map(&:classify).join("::")
  #       mailer_class_name += "::#{mailer_name.classify}"
  #     else
  #       mailer_class_name = "#{mailer_name.classify}"
  #     end
  #   end
  #
  #   # send mail.
  #   I18n.with_locale(self.locale) do
  #     mailer_class_name.constantize.send(
  #       action_name.to_sym,
  #       :to => recipient
  #     ).deliver
  #   end
  # end
end
