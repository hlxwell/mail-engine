class CreateTemplatePartials < ActiveRecord::Migration
  def self.up
    create_table :template_partials do |t|
      t.string :placeholder_name
      t.integer :mail_template_id
      t.integer :partial_id
    end
  end

  def self.down
    drop_table :template_partials
  end
end