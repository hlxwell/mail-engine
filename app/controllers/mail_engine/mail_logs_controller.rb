class MailEngine::MailLogsController < MailEngine::ApplicationController
  before_filter :find_model

  def index
    @mail_logs = MailLog.order("created_at desc").page(params[:page]).per(20)
  end

  def show
  end

  def destroy
    @mail_log.destroy
    redirect_to mail_logs_path
  end

  private

  def find_model
    @mail_log = MailLog.find(params[:id]) if params[:id].present?
  end
end