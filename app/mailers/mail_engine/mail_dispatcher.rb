class MailEngine::MailDispatcher < ActionMailer::Base
  default :from => MailEngine::Base.current_config["default_from"]
  sendgrid_header do
    category MailEngine::Base.current_config["sendgrid"]["sendgrid_category"]
    filters {
      opentrack "enable" => 1
      clicktrack "enable" => 1
      subscriptiontrack "enable" => 0
      template "enable" => 0
      footer "enable" => 0
    }
  end

  protected

  ###
  # MailEngine::MailDispatcher.{any template name}(
  #   :subject => 'hello',
  #   :to => 'm@theplant.jp',
  #   :values => {:username => @user.name}
  # ).deliver
  #
  def self.method_missing(method, *args)
    return super if respond_to?(method)

    options = args.dup.extract_options!
    options[:locale] ||= I18n.locale

    templates = MailEngine::MailTemplate.where(:path => method, :locale => options[:locale], :for_marketing => true, :partial => false).order('format desc').all
    raise "No Template added." if templates.blank?

    subject = templates.first.subject

    # generate the method for db template.
    class_eval <<-METHOD
      def #{method} options
        ### extract mail options, used for mail method.
        mail_options = {}
        mail_options[:subject] = "#{%Q{#{subject}}}"

        options.delete_if {|key, value|
          if [:subject, :to, :from, :cc, :bcc, :reply_to, :date].include?(key.to_sym)
            mail_options[key] = value
            true
          else
            false
          end
        }

        ### store :values to instance value
        (options[:values]||[]).each do |key, value|
          instance_variable_set "@" + key.to_s, value
        end

        mail mail_options
      end
    METHOD

    new(method, *args).message
  end
end