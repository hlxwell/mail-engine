# == Schema Information
#
# Table name: mail_template_files
#
#  id               :integer         not null, primary key
#  mail_template_id :integer
#  file             :string(255)
#  size             :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class MailEngine::MailTemplateFile < ActiveRecord::Base
  mount_uploader :file, MailEngine::TemplateFileUploader

  validates :file, :presence => true

  belongs_to :mail_template
  delegate :url, :to => :file
  after_save :replace_url_in_mail_template

  def image?
    return false if attributes["file"].blank?
    File.basename(attributes["file"]) =~ /\.(j(e)?pg)|(png)|(gif)$/i
  end

  def replace_url_in_mail_template
    if self.file_changed? and self.file_was.present?
      self.mail_template.update_attribute :body,
        MailEngine::HtmlDocumentAssetsReplacer.replace_resource_in_html(
          self.mail_template.body,
          self.file_was,
          File.basename(self.file.url),
          :filename
        )
    end
  end

  def clone *args
    file_clone = super *args
    file_clone.file = File.open(self.file.path)
    file_clone
  end
end