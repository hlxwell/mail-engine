class MailEngine::MailSchedulesController < MailEngine::ApplicationController
  before_filter :find_model

  def index
    @mail_schedules = MailSchedule.order("created_at desc").page(params[:page]).per(20)
  end

  def show
  end

  def edit
  end

  def destroy
    @mail_schedule.destroy
    redirect_to mail_schedules_path
  end

  def create
    @mail_schedule = MailSchedule.new(params[:mail_engine_mail_schedule].merge(:payload => params[:mail_engine_mail_schedule][:payload].try(:join, ',')))

    if @mail_schedule.save
      redirect_to mail_schedule_path(@mail_schedule), :notice => 'Mail schedule was successfully created.'
    else
      render "new"
    end
  end

  def new
    if MailTemplate.for_marketing.count == 0
      flash[:notice] = "Add Marketing mail template first."
      redirect_to :action => :index
    end
    @mail_schedule = MailSchedule.new
  end

  def update
    if @mail_schedule.update_attributes(params[:mail_engine_mail_schedule].merge(:payload => params[:mail_engine_mail_schedule][:payload].join(',')))
      redirect_to mail_schedule_path(@mail_schedule), :notice => 'Mail schedule was successfully updated.'
    else
      render "new"
    end
  end

  def send_test_mail
    @mail_schedule.send_test_mail_to!(params[:recipient], params[:sample_user_id])
    render :js => %Q{alert("Test Mail sent to #{params[:recipient]}"); $('#recipient').val('');}
  rescue => e
    render :js => %Q{alert("Test Mail failed to send to #{params[:recipient]}, due to #{e.to_s.gsub(/\n/, '')}"); $('#recipient').val('');}
  end

  def start
    if @mail_schedule.update_attribute :available, true
      render :js => %Q{alert('Start schedule successfully.'); showStopScheduleButton(#{@mail_schedule.id});}
    else
      render :js => %Q{alert('Failed to start schedule.')}
    end
  end

  def stop
    if @mail_schedule.update_attribute :available, false
      render :js => %Q{alert('Stop schedule successfully.'); showStartScheduleButton(#{@mail_schedule.id});}
    else
      render :js => %Q{alert('Failed to stop schedule.')}
    end
  end

  private
  def find_model
    @mail_schedule = MailSchedule.find(params[:id]) if params[:id]
  end
end