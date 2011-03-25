class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :email
      t.string :locale, :default => 'en'
      t.string :firstname
      t.string :lastname

      t.timestamps
    end

    User.create! :email => "m@theplant.jp", :firstname => "Michael", :lastname => "He", :locale => "en"
  end

  def self.down
    drop_table :users
  end
end
