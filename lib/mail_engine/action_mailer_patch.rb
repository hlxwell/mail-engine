### override mail method
module ActionMailer
  class Base
    alias_method :origin_mail, :mail
    def mail(headers={}, &block)
      # order by latest uploaded, for get the latest updated 'subject'
      current_template = MailEngine::MailTemplate.where(:path => "#{controller_path}/#{action_name}", :locale => I18n.locale, :partial => false).order("updated_at desc").first

      # {'username' => @username, 'gender' => @gender}
      instance_variable_hash = {}
      self.instance_variables.each { |var| instance_variable_hash[var.sub(/^@/,'')] = self.instance_variable_get(var) }

      headers[:subject] = Liquid::Template.parse(current_template.subject).render(instance_variable_hash) if current_template.present?
      headers[:message_id] = "#{controller_path}/#{action_name}"

      # Add sendgrid header before sending mail.
      # Why here but not add to default_params of action_mailer? because the receiver email [:to] only can get here.
      if self.sendgrid_config
        # if add "intercept_email" option in config
        receiver = if (intercept_email = MailEngine::Base.current_config["intercept_email"]).present?
                     headers[:to] = intercept_email
                   else
                     headers[:to]
                   end
        self.sendgrid_config.set_send_to receiver
        origin_mail(headers.merge(self.sendgrid_config.to_hash), &block)
      else
        origin_mail(headers, &block)
      end
    end

  protected

    ###
    # REASON TO OVERRIDE THIS METHOD:
    # need to set layout and pass partial path to each format of mail template.
    #
    # Completed copied from lib/action_mailer/base.rb#665
    def collect_responses_and_parts_order(headers) #:nodoc:
      responses, parts_order = [], nil

      if block_given?
        collector = ActionMailer::Collector.new(lookup_context) { render(action_name) }
        yield(collector)
        parts_order = collector.responses.map { |r| r[:content_type] }
        responses  = collector.responses
      elsif headers[:body]
        responses << {
          :body => headers.delete(:body),
          :content_type => self.class.default[:content_type] || "text/plain"
        }
      else
        templates_path = headers.delete(:template_path) || self.class.mailer_name
        templates_name = headers.delete(:template_name) || action_name
        each_template(templates_path, templates_name) do |template|
          self.formats = template.formats
          responses <<  if lookup_context.view_paths.detect {|resolver| resolver.class.to_s == "MailEngine::MailTemplateResolver" }
                          {
                            :body => render_with_layout_and_partials(template.mime_type.to_sym.to_s),
                            :content_type => template.mime_type.to_s
                          }
                        else
                          {
                            :body => render(:template => template),
                            :content_type => template.mime_type.to_s
                          }
                        end
        end
      end

      [responses, parts_order]
    end

    # render template with layout and partials
    def render_with_layout_and_partials(format)
      # looking for system mail.
      template = MailEngine::MailTemplate.where(:path => "#{controller_path}/#{action_name}", :format => format, :locale => I18n.locale, :partial => false, :for_marketing => false).first
      # looking for marketing mail.
      template = MailEngine::MailTemplate.where(:path => action_name, :format => format, :locale => I18n.locale, :partial => false, :for_marketing => true).first if template.blank?

      # if found db template set the layout and partial for it.
      if template
        related_partial_paths = {}
        # set @footer or @header
        template.template_partials.each do |tmp|
          related_partial_paths["#{tmp.placeholder_name}_path".to_sym] = tmp.partial.path
        end

        # set layout
        render :template => "#{controller_path}/#{action_name}", :layout => "layouts/mail_engine/mail_template_layouts/#{template.layout}", :locals => related_partial_paths
      else
        # if not found db template should render file template
        render(action_name)
     end
    end
  end
end