module MailEngine
  class CopyMigrations < Rails::Generators::Base
    desc "Add mail template model migration to your application."
    source_root File.join(File.dirname(__FILE__))

    def copy_migrations
      [
        "20110114030841_create_table_mail_template",
        "20110126030525_create_mail_schedules",
        "20110204114145_create_template_partials",
        "20110206025002_create_mail_logs",
        "20110217062316_create_mail_template_files"
      ].each do |filename|
        from = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "db", "migrate", "#{filename}.rb"))
        to = File.expand_path(File.join(Rails.root, "db", "migrate", "#{filename}.rb"))
        copy_file from, to
      end
    end

  end # CreateMigration
end # MailEngine