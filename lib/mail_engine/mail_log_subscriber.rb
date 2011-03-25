# real data
# {
#   :mailer=>"UserMailer",
#   :subject=>"Notify",
#   :date=>nil,
#   :message_id=>nil,
#   :mail=>
#   "Date: Sun, 06 Feb 2011 11:11:54 +0800\r\nFrom: info@itjob.fm\r\nTo: m@theplant.jp\r\nMessage-ID: <4d4e117a766f9_13db981b0456013966@localhost.mail>\r\nSubject: Notify\r\nMime-Version: 1.0\r\nContent-Type: text/plain;\r\n charset=UTF-8\r\nContent-Transfer-Encoding: 7bit\r\nX-SMTPAPI: {\"category\": \"itjob\", \"to\": [\"m@theplant.jp\"], \"filters\":\r\n {\"opentrack\": {\"settings\": {\"enable\":1}}, \"clicktrack\": {\"settings\":\r\n {\"enable\":1}}, \"template\": {\"settings\": {\"enable\":0}}, \"footer\": {\"settings\":\r\n {\"enable\":0}}, \"subscriptiontrack\": {\"settings\": {\"text/html\": \"Unsubscribe\r\n link.html\", \"landing\": \"http://landing.com\", \"url\": \"http://url.com\",\r\n \"enable\":1,\"text/plain\": \"Unsubscribe link.txt\"}}}}\r\n\r\n",
#   :to=>["m@theplant.jp"],
#   :from=>["info@itjob.fm"]
# }

module MailEngine

  # I don't know if it's a better solution, Seems below one is another good solution.
  #
  #   initializer "mail_engine.register_mail_log" do
  #     ActionMailer::Base.register_interceptor MailEngine::MailLog
  #   end
  #
  class MailLogSubscriber < ActiveSupport::LogSubscriber
    def deliver(event)
      log_mail_config = MailEngine::Base.current_config["log_mail"]
      return false if log_mail_config.blank? or !log_mail_config

      MailEngine::MailLog.create!({
        :mail_template_path => event.payload[:message_id],
        :subject            => event.payload[:subject],
        :raw_body           => event.payload[:mail],
        :recipient          => event.payload[:to].inspect,
        :sender             => event.payload[:from].inspect,
        :mime_type          => event.payload[:mail].scan(/Content-Type: ([^;\r\n]*)/).flatten.inspect
      })
    end
  end
end

MailEngine::MailLogSubscriber.attach_to :action_mailer