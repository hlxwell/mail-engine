class CreateMailLogs < ActiveRecord::Migration
  def self.up
    create_table :mail_logs do |t|
      t.string    "mail_template_path"
      t.string    "recipient"
      t.string    "sender"
      t.string    "subject"
      t.string    "mime_type"
      t.text      "raw_body"
      t.timestamps
    end
  end

  def self.down
    drop_table :mail_logs
  end
end