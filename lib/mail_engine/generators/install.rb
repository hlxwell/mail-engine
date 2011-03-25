module MailEngine
  class Install < Rails::Generators::Base
    desc "Install Mail Engine."
    source_root File.join(File.dirname(__FILE__))

    def create_config
      say "Create Configure file to project...", :yellow
      MailEngine::CreateConfig.start
    end

    def copy_resources
      say "Copying Resource Files to project...", :yellow
      MailEngine::CopyResources.start
    end

    def copy_migrations
      say "Copying Migration Files to project...", :yellow
      MailEngine::CopyMigrations.start
    end

  end
end # MailEngine