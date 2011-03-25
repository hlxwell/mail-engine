module MailEngine
  class Base
    cattr_accessor :configurations, :instance_writer => false
    @@configurations = HashWithIndifferentAccess.new

    class << self
      # return current runtime environment config hash.
      # === example
      #
      #   log_mail: true
      #   user_class_name: "User"
      #   mount_at: "/admin"
      #   access_check_method: "logged_in?"
      #   sendgrid:
      #     sendgrid_user: "xxx@theplant.jp"
      #     sendgrid_key: "xxx"
      #     sendgrid_category: "development"
      #
      def current_config
        MailEngine::Base.configurations[Rails.env] || {}
      end

      # send mail template with given data.
      # === example
      #
      #   MailEngine::Base.send_marketing_mail("newsletter", :to => 'm@theplant.jp', :values => {:users => MailEngine::USER_MODEL.last})
      #
      def send_marketing_mail(template, *args)
        options = args.extract_options!
        options[:locale] ||= I18n.locale

        # ensure the :to parameter.
        raise "Should specify :to option" if options[:to].blank?

        # find the template from database.
        unless mail_template = MailEngine::MailTemplate.where(:path => template, :locale => options[:locale], :for_marketing => true, :partial => false).first
          raise "Can't find the template: #{template}"
        end

        options[:subject] ||= mail_template.subject
        I18n.with_locale(mail_template.locale) do
          MailEngine::MailDispatcher.send(template, options).deliver
        end
      end

    end
  end
end