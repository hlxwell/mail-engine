module MailEngine
  class CreateConfig < Rails::Generators::Base
    desc "Add mail template config file."
    source_root File.expand_path("../templates", __FILE__)

    # def generate_config
    #   case backend_type
    #   when "amazon"
    #   when "sendgrid"
    #   when "sendmail"
    #   when "smtp"
    #   else
    #   end
    # end

    def create_config_file
      template "mail_engine_config.yml", "config/mail_engine_config.yml"
    end
  end
end # MailEngine