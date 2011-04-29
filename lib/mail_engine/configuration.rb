module MailEngine
  class ConfigurationError < StandardError; end
  # Load configure file from config/mail_engine_config.yml
  # you can access the config by MailEngine::Base.current_config[]
  class Configuration
    class << self
      def load_and_check
        require 'erb' # make config file support erb tags. like <% %>
        config_path = File.join(Rails.root, "config", "mail_engine_config.yml")
        MailEngine::Base.configurations = {}
        MailEngine::Base.configurations = YAML::load(ERB.new(IO.read(config_path)).result) if File.exist?(config_path)
        config_check
      end

      ### Need check below config options
      #
      # log_mail: true
      # user_class_name: 'User'
      # user_locale_column: 'locale'
      # mount_at: '/admin/mail_engine'
      # intercept_email: 'your email'
      # default_from: 'you email'
      # access_check_method: 'logged_in?'
      # sendgrid:
      #   sendgrid_user: 'you send grid user'
      #   sendgrid_key: 'you send grid password'
      #   sendgrid_category: 'your send grid category'
      #
      def config_check
        if MailEngine::Base.current_config.blank?
          puts "\e[1;31;40m[Mail Engine Warning]\e[0m Not found mail_engine_config.yml, so mail_engine won't be able to work."
          raise ConfigurationError.new("did't find config file at config/mail_engine_config.yml")
        end

        ### if not set them will has some bad news
        # user_locale_column
        # access_check_method

        %w{log_mail user_class_name mount_at default_from}.each do |option|
          raise ConfigurationError.new("Please add :#{option} config into mail_engine_config.yml.") if MailEngine::Base.current_config[option].blank?
        end

        %w{sendgrid_category sendgrid_user sendgrid_key}.each do |option|
          raise ConfigurationError.new("Please add :#{option} config under not :sendgrid into mail_engine_config.yml.") if MailEngine::Base.current_config["sendgrid"][option].blank?
        end
      rescue ConfigurationError => e
        puts <<-NOTE
\e[1;31;40m[Mail Engine Warning - Below is a sample config]\e[0m
===============================================
  log_mail: true
  user_class_name: 'User'
  user_locale_column: 'locale'
  mount_at: '/admin/mail_engine'
  intercept_email: 'your email'
  default_from: 'you email'
  access_check_method: 'logged_in?'
  sendgrid:
    sendgrid_user: 'you send grid user'
    sendgrid_key: 'you send grid password'
    sendgrid_category: 'your send grid category'
===============================================
        NOTE
      end

    end
  end
end