module MailEngine
  class Engine < Rails::Engine
    require 'mail_engine'
    require 'carrierwave'
    require 'kaminari'
    require 'deep_cloneable'
    require 'liquid'
    require 'mail_engine/mail_log_subscriber'
    require 'mail_engine/zip_processor'
    require 'mail_engine/html_document_assets_replacer'
    require 'mail_engine/liquid_view_patch/liquid_view'

    initializer "mail_engine" do
      ActionMailer::Base.send(:include, MailEngine::Sendgrid::Base)
      require 'mail_engine/action_mailer_patch'
    end

    initializer "mail_engine.register_liquid_template" do
      ActionView::Template.register_template_handler(:liquid, LiquidView)
    end

    initializer "mail_engine.register_database_template" do
      ActionMailer::Base.layout "layouts/mail_engine/mail_template_layouts/none"
      ActionMailer::Base.prepend_view_path(MailEngine::MailTemplateResolver.instance)
    end

    initializer "mail_engine.add_acts_as_mail_receiver" do
      ActiveRecord::Base.send(:include, MailEngine::ActsAsMailReceiver)
    end

    rake_tasks do
      load "mail_engine/tasks/sendmail.rake"
      load "mail_engine/tasks/export_mail_engine_database.rake"
    end

    generators do
      require 'mail_engine/generators/install.rb'
      require 'mail_engine/generators/create_config.rb'
      require 'mail_engine/generators/copy_resources.rb'
      require 'mail_engine/generators/copy_migrations.rb'
    end

    config.to_prepare do
      # load config
      MailEngine::Configuration.load_and_check

      MailEngine::USER_MODEL = MailEngine::Base.current_config["user_class_name"].constantize unless defined?(MailEngine::USER_MODEL)
    end
  end
end