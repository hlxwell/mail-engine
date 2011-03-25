require 'test_helper'

class UserMailerTest < ActionController::TestCase
  context "UserMailer" do
    should "has sendgrid header" do
      assert UserMailer.sendgrid_config.to_hash["X-SMTPAPI"].present?
    end

    should "send to safe mail address" do
      MailEngine::Base.current_config["intercept_email"] = "xxx@xxx.com"
      mail = UserMailer.notify("x@x.com").deliver
      assert_equal mail.to, ["xxx@xxx.com"]
      assert UserMailer.sendgrid_config.to_hash["X-SMTPAPI"].include?("[\"xxx@xxx.com\"]")
    end

    should "only send mail to the receiver" do
      UserMailer.notify("x@x.com").deliver
      assert UserMailer.sendgrid_config.to_hash["X-SMTPAPI"].include?("[\"x@x.com\"]")

      UserMailer.notify("y@y.com").deliver
      assert UserMailer.sendgrid_config.to_hash["X-SMTPAPI"].include?("[\"y@y.com\"]")
    end

    should "override subject by db tempate.subject" do
      @template = FactoryGirl.build(:system_mail_template_with_footer, :format => "html")
      assert_equal "subject in mailer", UserMailer.notify("x@x.com").subject
      @template.save
      assert_equal @template.subject, UserMailer.notify("x@x.com").subject
    end
  end
end