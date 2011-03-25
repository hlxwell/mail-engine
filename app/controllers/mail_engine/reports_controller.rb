class MailEngine::ReportsController < MailEngine::ApplicationController
  def index
    @pie_chart_columns = ["bounces", "unique_opens", "spamreports", "blocks", "unopened"]
    @stat_columns = [
      "requests",
      "delivered",
      "blocks",
      "invalid_email",
      "clicks",
      "unique_clicks",
      "opens",
      "unique_opens",
      "bounces",
      "repeat_bounces",
      "spamreports",
      "repeat_spamreports",
      "unsubscribes",
      "repeat_unsubscribes"
    ]
    @stats_data = if params[:report] and params[:report][:from] and params[:report][:to]
                    MailEngine::Sendgrid::RestApi.stats(:start_date => params[:report][:from], :end_date => params[:report][:to])
                  else
                    MailEngine::Sendgrid::RestApi.stats(:days => 7)
                  end
  end

  def chart
    if ['bounces', 'blocks', 'spamreports', 'invalidemails'].include?(params[:type])
      @result = Array.wrap(MailEngine::Sendgrid::RestApi.send(params[:type], :date => 1)) || []
      render "mail_engine/reports/charts/#{params[:type]}"
    else
      flash[:notice] = "Error chart type."
      redirect_to :back
    end
  end
end