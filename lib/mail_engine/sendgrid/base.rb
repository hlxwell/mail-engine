# ### Usage
# class UserMailer < SendgridMailer
#   sendgrid_header do
#     category "itjob"
#
#     filters {
#       opentrack "enable" => 1
#       clicktrack "enable" => 1
#       gravatar "enable" => 1
#       template "enable" => 1, "text/html" => "<p>Thanks for your subscription.</p>"
#       footer "enable" => 1, "text/plain" => "Thanks for your subscription.", "text/html" => "<p>Thanks for your subscription.</p>"
#     }
#   end
#
#   def notification(user)
#     mail :to => "x@x.com" do |format|
#       format.text
#       format.html_from_db
#     end
#   end
# end

require 'active_support/concern'

module MailEngine
  module Sendgrid
    module Base
      extend ActiveSupport::Concern

      included do
        cattr_accessor :sendgrid_config
      end

      module ClassMethods
        def sendgrid_header(&block)
          self.sendgrid_config = SmtpApi.new
          self.sendgrid_config.instance_eval(&block)
        end
      end

      module InstanceMethods
      end

    end
  end
end