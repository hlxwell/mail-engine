class User < ActiveRecord::Base
  # groups
  scope :english_users, where(:locale => 'en')
  scope :chinese_users, where(:locale => 'zh')

  ###
  # here you can define:
  # 1. Which columns can be acted as payload columns.
  # 2. Which scope can be user group.
  acts_as_mail_receiver :payload_columns => %w{firstname lastname},
                        :groups => %w{all english_users chinese_users}
end