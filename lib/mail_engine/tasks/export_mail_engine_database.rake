namespace :mail_engine do
  desc "Check mail schedule table and send the scheduled mail."
  task :export_mail_engine_database => :environment do
    datetime = Time.now.strftime("%Y%m%d")

    db_config = YAML.load_file(File.join(Rails.root, 'config', 'database.yml'))[Rails.env]
    db_username = db_config["username"]
    db_password = db_config["password"]
    db_database = db_config["database"]
    db_socket   = db_config["socket"]
    tables = ['mail_templates', 'mail_schedules', "mail_template_files", "template_partials"]
    backup_file_path = File.join(Rails.root,"tmp", "mail_engine_backup", "#{db_database}_#{datetime}.sql")

    system "mkdir -p #{File.join(Rails.root,"tmp", "mail_engine_backup")}"
    system "mysqldump -u #{db_username} -S #{db_socket} -p'#{db_password}' #{db_database} #{tables.join(' ')}> #{backup_file_path}"
  end
end