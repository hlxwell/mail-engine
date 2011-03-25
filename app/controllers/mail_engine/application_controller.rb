class MailEngine::ApplicationController < ApplicationController
  # used when mail_template preview.
  prepend_view_path MailEngine::MailTemplateResolver.instance

  include MailEngine
  helper MailEngine::MailEngineHelper

  layout 'mail_engine/mail_engine'

  # set the access check method which set in the config.
  if MailEngine::Base.current_config["access_check_method"].present?
    before_filter MailEngine::Base.current_config["access_check_method"]
  end

  ###
  # return js o close fancy box and refresh page.
  def close_modal_and_refresh
    render :text => "<script>parent.$.fancybox.close();parent.window.location.reload();</script>"
  end
end