class CreateTableMailTemplate < ActiveRecord::Migration
  def self.up
    create_table :mail_templates do |t|
      t.string :name
      t.string :subject
      t.string :path
      t.string :format, :default => 'html'
      t.string :locale
      t.string :handler, :default => 'liquid'
      t.text :body
      t.boolean :partial, :default => false
      t.boolean :for_marketing, :default => false
      t.string :layout, :default => 'none'
      t.string :zip_file

      t.timestamps
    end
  end

  def self.down
    drop_table :mail_templates
  end
end