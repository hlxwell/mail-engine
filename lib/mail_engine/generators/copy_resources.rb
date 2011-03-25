module MailEngine
  class CopyResources < Rails::Generators::Base
    desc "Copy javascripts and css files to your application."
    source_root File.join(File.dirname(__FILE__))

    def copy_resources
      from = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "public"))
      to = File.expand_path(File.join(Rails.root, "public"))
      directory from, to
    end

  end # CreateMigration
end