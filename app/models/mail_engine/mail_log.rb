# == Schema Information
#
# Table name: mail_logs
#
#  id                 :integer         not null, primary key
#  mail_template_path :string(255)
#  recipient          :string(255)
#  sender             :string(255)
#  subject            :string(255)
#  mime_type          :string(255)
#  raw_body           :text
#  created_at         :datetime
#  updated_at         :datetime
#

class MailEngine::MailLog < ActiveRecord::Base
  validates_presence_of :mail_template_path

  # # Callback of Mail gem when delivering mails
  # def self.delivering_email mail
  #   # pp email.body.raw_source
  #   # pp email.to
  #   # pp email.from
  #   # pp email.subject
  #   # pp email.mime_type
  #
  #   ##################
  #   # pp mail.mime_type
  #   # pp mail.content_type
  #   # pp mail.from            #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
  #   # pp mail.to              #=> 'bob@test.lindsaar.net'
  #   # pp mail.subject         #=> "This is the subject"
  #   # pp mail.body.decoded    #=> 'This is the body of the email...
  #   ###################
  #
  #   # pp mail.parts.map { |p| p.content_type }  #=> ['text/plain', 'application/pdf']
  #   # pp mail.parts.map { |p| p.class }         #=> [Mail::Message, Mail::Message]
  #   # pp mail.parts[0].content_type_parameters  #=> {'charset' => 'ISO-8859-1'}
  #   # pp mail.parts[1].content_type_parameters  #=> {'name' => 'my.pdf'}
  #
  #   # mail_type = email.header["X-mail-type"].value
  #   # record = create! :recipient => email.to.join(","), :mail_type => mail_type
  #   # email.encoded # kick email to set content_transfer_encoding
  #   # # The new body needs to be already encoded, as Mail expects the body to be encoded already (after calling #encoded)
  #   # encoding = Mail::Encodings.get_encoding email.content_transfer_encoding
  #   # new_body = encoding.encode email.body.to_s.sub("/t/id.gif", "/t/#{record.open_token}.gif")
  #   # email.body(new_body)
  #   #
  #   # record.update_attributes! :body => email.body.to_s, :raw_text => email.encoded
  # end
end