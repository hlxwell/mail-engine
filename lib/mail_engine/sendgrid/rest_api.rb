require 'httparty'

### Usage
# MailEngine::Sendgrid::RestApi.stats
module MailEngine
  module Sendgrid
    class RestApiError < StandardError; end

    class RestApi
      include HTTParty
      base_uri "https://sendgrid.com/api"
      default_params :api_key => MailEngine::Base.current_config["sendgrid"]["sendgrid_key"], :api_user => MailEngine::Base.current_config["sendgrid"]["sendgrid_user"]

      class << self
        # <stats>
        #   <day>
        #     <date>2009-06-20</date>
        #     <requests>12342</requests>
        #     <bounces>12</bounces>
        #     <clicks>10223</clicks>
        #     <opens>9992</opens>
        #     <spamreports>5</spamreports>
        #     <unique_clicks>3</unique_clicks>
        #     <unique_opens>6</unique_opens>
        #     <blocked>7</blocked>
        #   </day>
        # </stats>
        def stats options = {}
          response = get "/stats.get.xml", :query => options
          response["stats"].try(:send, :[], "day")
        end

        # <bounces>
        #   <bounce>
        #     <email>email1@domain.com</email>
        #     <status>5.1.1</status>
        #     <reason>host [127.0.0.1] said: 550 5.1.1 unknown or illegal user: email1@domain.com</reason>
        #     <created>2009-06-10 12:40:30</created>
        #   </bounce>
        # </bounces>
        def bounces options = {}
          response = get "/bounces.get.xml", :query => options
          response["bounces"].try(:send, :[], "bounce")
        end

        # <spamreports>
        #   <spamreport>
        #     <email>email1@domain.com</email>
        #     <created>2009-06-10 12:40:30</created>
        #   </spamreport>
        # </spamreports>
        def spamreports options = {}
          response = get "/spamreports.get.xml", :query => options
          response["spamreports"].try(:send, :[], "spamreport")
        end

        # <invalidemails>
        #   <invalidemail>
        #     <email>isaac@hotmail.comm</email>
        #     <reason>Mail domain mentioned in email address is unknown</reason>
        #     <created>2009-06-10 12:40:30</created>
        #   </invalidemail>
        # </invalidemails>
        def invalidemails options = {}
          response = get "/invalidemails.get.xml", :query => options
          response["invalidemails"].try(:send, :[], "invalidemail")
        end

        # <blocks>
        #   <block>
        #     <email>exp_block_0466@sendgrid.com</email>
        #     <status></status>
        #     <reason>Some random block reason</reason>
        #     <created>2010-11-08 20:39:29</created>
        #   </block>
        # </blocks>
        def blocks options = {}
          response = get "/blocks.get.xml", :query => options
          response["blocks"].try(:send, :[], "block")
        end

      end
    end # end of rest api class
  end # end of sendgrid module
end # end of mail engine module
