# == Schema Information
#
# Table name: template_partials
#
#  id               :integer         not null, primary key
#  placeholder_name :string(255)
#  mail_template_id :integer
#  partial_id       :integer
#

class MailEngine::TemplatePartial < ActiveRecord::Base
  validates_presence_of :partial_id, :placeholder_name

  belongs_to :mail_template
  belongs_to :partial, :class_name => "MailTemplate", :foreign_key => :partial_id

  scope :header, where(:placeholder_name => 'header')
  scope :footer, where(:placeholder_name => 'footer')
end