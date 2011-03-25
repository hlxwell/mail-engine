require 'active_support'
require "action_view/template"
require 'mail_engine/engine'

module MailEngine
  extend ::ActiveSupport::Autoload

  # used for looking up which layout needs which placeholders.
  PLACEHOLDERS_IN_LAYOUT = {
    :none => [],
    :only_footer => ['footer'],
    :header_and_footer => ['header', 'footer']
  }

  autoload :Base
  autoload :Sendgrid
  autoload :Mailer
  autoload :ActsAsMailReceiver
  autoload :Configuration
  autoload :MailTemplateResolver
end