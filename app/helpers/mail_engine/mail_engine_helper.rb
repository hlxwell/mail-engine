module MailEngine
  module MailEngineHelper

    def show_no_record collection, &block
      if collection.is_a?(Array) ? collection.blank? : collection.try(:all).blank?
        return raw("<div class='notice' style='margin-top:10px'>No Record</div>")
      else
        block.call
        return ""
      end
    end

    def show_percentage reality, total
      return "-" if total <= 0
      percentage = (reality / total) * 100
      return "#{percentage.round(2)}%"
    end

    def mail_template_list_title type
      case type
      when "partial"
        "Mail Template Partial"
      when "system", "marketing"
        "#{type.try(:capitalize)} Mail Template"
      else
        "Mail Template"
      end
    end

  end
end