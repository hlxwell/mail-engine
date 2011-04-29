class MailEngine::DashboardController < MailEngine::ApplicationController
  def index
    @pie_chart_columns = ["bounces", "unique_opens", "spamreports", "blocks", "unopened"]
    @data_of_today = MailEngine::Sendgrid::RestApi.stats || {}
    # unopened data needs you calculate by yourself.
    @data_of_today.merge!("unopened" => (@data_of_today["delivered"].to_i - @data_of_today["unique_opens"].to_i))
  end
end