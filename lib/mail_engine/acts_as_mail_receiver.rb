require 'active_support/concern'

# Used for setting a User model as a Mail Receiver Data Provider
module MailEngine
  module ActsAsMailReceiver
    extend ActiveSupport::Concern

    included do
      cattr_accessor :payload_columns, :groups
    end

    module ClassMethods
      ###
      # NOTICE: Please put this code below any "scope" statement.
      # Here you can define:
      # 1. Which columns can be acted as payload items.
      # 2. Which methods can be user group scopes.
      #
      # ==== Example
      #
      #    class User < AR
      #      acts_as_mail_receiver :payload_columns => %w{firstname lastname},
      #                            :groups => %w{all english_users chinese_users},
      #                            :skip_method_existance_check => true
      #    end
      #
      def acts_as_mail_receiver(options)
        [:payload_columns, :groups].each do |key|
          methods_array = Array.wrap(options[key]) || []
          self.send("#{key}=", methods_array)
        end
        check_method_existance! unless options[:skip_method_existance_check]
      end

    private

      # Check if the methods is existed in the User model.
      # If raise error.
      def check_method_existance!
        return false if defined?(Rake) && Rake.application.top_level_tasks.include?("db:migrate")

        nonexist_groups = self.groups.select do |group|
          !self.methods.include?(group)
        end

        nonexist_payload_columns = self.payload_columns.select do |col|
          !self.instance_methods.include?(col) and !self.column_names.include?(col)
        end

        raise "Doesn't find group methods in #{self.name}:#{nonexist_groups.inspect}" if nonexist_groups.present?
        raise "Doesn't find payload column methods in #{self.name}:#{nonexist_payload_columns.inspect}" if nonexist_payload_columns.present?
      end
    end

  end
end