class CreateMailTemplateFiles < ActiveRecord::Migration
  def self.up
    create_table :mail_template_files do |t|
      t.integer :mail_template_id
      t.string :file
      t.integer :size
      t.timestamps
    end
  end

  def self.down
    drop_table :mail_template_files
  end
end