class MailEngine::MailTemplatesController < MailEngine::ApplicationController
  before_filter :find_model

  def index
    @mail_templates = case params[:type]
                      when "marketing"
                        MailEngine::MailTemplate.for_marketing
                      when "system"
                        MailEngine::MailTemplate.for_system
                      when "partial"
                        MailEngine::MailTemplate.partial
                      else
                        redirect_to mail_templates_path(:type => "system")
                        return
                      end

    @mail_templates = @mail_templates.group("path").page(params[:page]).per(20)
  end

  def preview
    @mail_template = MailEngine::MailTemplate.new if @mail_template.blank?
    @mail_template.body = params[:new_body] if params[:new_body]
    render :layout => false
  end

  def body
    I18n.with_locale(@mail_template.locale) {
      if @mail_template.partial?
        render :partial => @mail_template.path,
               :layout => false,
               :content_type => Mime[@mail_template.format].to_s
      else
        # set @footer or @header
        related_partial_paths = {}
        @mail_template.template_partials.each { |tmp| related_partial_paths["#{tmp.placeholder_name}_path".to_sym] = tmp.partial.path }
        render :template => @mail_template.path,
               :layout => "layouts/mail_engine/mail_template_layouts/#{@mail_template.layout}",
               :locals => related_partial_paths
      end
    }
  end

  def duplicate
    if request.put?
      @duplicated_mail_template = @mail_template.duplicate(params[:mail_engine_mail_template])
      if @duplicated_mail_template.errors.blank?
        close_modal_and_refresh
        return
      end
    else
      @duplicated_mail_template = @mail_template
    end

    render :layout => "mail_engine/simple"
  end

  def destroy
    if @mail_template.partial_in_use?
      flash[:notice] = "Partial##{@mail_template.id} is in use, so can't be destroyed."
    else
      @mail_template.destroy
    end
    redirect_to mail_templates_path(:type => params[:type])
  end

  def create
    @mail_template = MailTemplate.new(params[:mail_engine_mail_template])
    if @mail_template.save
      redirect_to mail_template_path(@mail_template), :notice => 'Mail template was successfully created.'
    else
      render "new"
    end
  end

  def new
    @mail_template = MailTemplate.new :layout => 'none', :partial => params[:type] == 'partial'
  end

  def get_existed_subject
    subject = MailTemplate.get_subject_from_bother_template(params[:path], params[:locale], params[:for_marketing] == 'true')
    render :text => %Q{#{subject}}
  end

  def new_by_upload
    @mail_template = MailTemplate.new :layout => 'none', :format => 'html'
  end

  def create_by_upload
    @mail_template = MailTemplate.new(params[:mail_engine_mail_template])
    if @mail_template.save
      redirect_to mail_template_path(@mail_template), :notice => 'Mail template was successfully created.'
    else
      render "new_by_upload"
    end
  end

  def partial_options
    @tmp_mail_template = MailTemplate.new

    if @mail_template and @mail_template.persisted?
      @tmp_mail_template.layout = @mail_template.try(:layout)
      @tmp_mail_template.template_partials = @mail_template.try(:template_partials)
    end

    if params[:layout] != @tmp_mail_template.layout || @tmp_mail_template.template_partials.blank?
      @tmp_mail_template.template_partials.delete_if {|tmp| tmp.persisted?}
      case params[:layout]
      when 'none'
      when 'only_footer'
        @tmp_mail_template.template_partials.build :placeholder_name => 'footer'
      when 'header_and_footer'
        @tmp_mail_template.template_partials.build :placeholder_name => 'header'
        @tmp_mail_template.template_partials.build :placeholder_name => 'footer'
      else
      end
    end

    render :layout => false
  end

  def update
    if @mail_template.update_attributes(params[:mail_engine_mail_template])
      redirect_to mail_template_path(@mail_template), :notice => 'Mail template was successfully updated.'
    else
      render "edit"
    end
  end

  def show
  end

  def edit
  end

  def import
  end

  def import_from_files
    MailEngine::MailTemplate.import_from_files!(params[:import][:mailer_name])
    flash[:notice] = "Import successfully!"
  rescue => e
    flash[:notice] = "Import failed due to: #{e.to_s}"
  ensure
    render :import
  end

  private

  def find_model
    @mail_template = MailTemplate.find(params[:id]) if params[:id].present?
  end
end