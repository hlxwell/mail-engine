module MailEngine
  module Sendgrid
    extend ActiveSupport::Autoload

    autoload :Base
    autoload :SmtpApi
    autoload :RestApi
  end
end