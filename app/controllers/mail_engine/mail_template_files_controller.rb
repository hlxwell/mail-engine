class MailEngine::MailTemplateFilesController < MailEngine::ApplicationController
  layout "mail_engine/simple"
  before_filter :find_model

  def index
  end

  def edit
  end

  def show
  end

  def new
    @mail_template_file = @mail_template.mail_template_files.new
  end

  def create
    @mail_template_file = @mail_template.mail_template_files.build(params[:mail_engine_mail_template_file])
    if @mail_template_file.save
      close_modal_and_refresh
    else
      render :new
    end
  end

  def update
    if @mail_template_file.update_attributes(params[:mail_engine_mail_template_file])
      close_modal_and_refresh
    else
      render :edit
    end
  end

  def destroy
    @mail_template_file.destroy
    render :js => "window.location.reload()"
  end

  private

  def find_model
    @mail_template = MailTemplate.find(params[:mail_template_id]) if params[:mail_template_id].present?
    @mail_template_file = MailTemplateFile.find(params[:id]) if params[:id].present?
  end
end