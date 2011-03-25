class UserMailer < ActionMailer::Base
  default :from => MailEngine::Base.current_config["default_from"]
  sendgrid_header do
    category MailEngine::Base.current_config["sendgrid"]["sendgrid_category"]

    filters {
      opentrack "enable" => 1
      clicktrack "enable" => 1
      subscriptiontrack "enable" => 0
      template "enable" => 0
      footer "enable" => 0
    }
  end

  def notify(to = "hlxwell@gmail.com")
    @username = "Michael He"

    # html must below text
    # should use subject in the db mail template.
    mail :to => to, :subject => "subject in mailer"
  end

  def notify_to_user(user)
    @firstname = user.firstname
    @lastname = user.lastname

    # html must below text
    mail :to => user.email
  end
end