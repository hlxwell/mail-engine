require 'json'

module MailEngine
  module Sendgrid
    class FilterSetting
      attr_accessor :data

      def initialize
        @data = {}
      end

      ### Please check API: http://sendgrid.com/documentation/apps
      #
      # sendgrid_header do
      #   category "itjob"
      #
      #   filters {
      #     opentrack "enable" => 1
      #     clicktrack "enable" => 1
      #     subscriptiontrack "enable" => 1, "text/html" => "Unsubscribe link.html", "text/plain" => "Unsubscribe link.txt", "url" => "http://url.com", "landing" => "http://landing.com"
      #     template "enable" => 1, "text/html" => "<p>Thanks for your subscription.</p>"
      #     footer "enable" => 1, "text/plain" => "Thanks for your subscription.", "text/html" => "<p>Thanks for your subscription.</p>"
      #   }
      # end
      #
      %w(opentrack clicktrack subscriptiontrack footer spamcheck ganalytics template bcc list domainkeys).each do |method_name|
        define_method method_name do |config_hash|
          validate_config! method_name, config_hash
          @data[method_name] ||= {}
          @data[method_name]["settings"] = config_hash
        end
      end

      private

      def validate_config!(name, config_hash)
        raise "'#{name}' Config should be a hash value." unless config_hash.is_a?(Hash)
      end
    end

    ### smtp api class
    class SmtpApi
      def initialize()
        @data = {}
      end

      def category(cat)
        @data['category'] = cat
      end

      def filters(&block)
        filter_setting = FilterSetting.new
        filter_setting.instance_eval(&block)
        @data["filters"] = filter_setting.data
      end

      # for now only allow to send to one receiver once.
      # maybe we don't like people received a mail which allow people to view all receivers
      def set_send_to(to)
        @data['to'] ||= []
        @data['to'] = Array.wrap(to)
        @data['to'].uniq!
      end

      def add_to(to)
        @data['to'] ||= []
        @data['to'] += Array.wrap(to)
        @data['to'].uniq!
      end

      def add_sub_val(var, val)
        @data['sub'] ||= {}
        @data['sub'][var] = Array.wrap(val)
      end

      def set_unique_args(val)
        @data['unique_args'] = val if val.instance_of?(Hash)
      end

      def to_json
        @data.to_json.gsub(/(["\]}])([,:])(["\[{])/, '\\1\\2 \\3')
      end

      def to_hash
        {'X-SMTPAPI' => self.to_json}
      end

      def to_s
        'X-SMTPAPI: %s' % self.to_json
      end
    end
  end
end