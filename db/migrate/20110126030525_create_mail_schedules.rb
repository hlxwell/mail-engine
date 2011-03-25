class CreateMailSchedules < ActiveRecord::Migration
  def self.up
    create_table :mail_schedules do |t|
      t.string :name
      t.integer :mail_template_id
      t.string :user_group
      t.integer :count, :default => 0
      t.integer :sent_count, :default => 0
      t.string :period
      t.string :payload
      t.datetime :first_send_at
      t.datetime :last_sent_at
      t.boolean :available, :default => false
      t.string :default_locale

      t.timestamps
    end
  end

  def self.down
    drop_table :mail_schedules
  end
end