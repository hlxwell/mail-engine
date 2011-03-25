module MailEngine
  class HtmlDocumentAssetsReplacer

    class << self
      # One requirement:
      # Need one html file in the zip
      def check! file_paths
        html_file_pathes = file_paths.select { |path| path =~ /\/[^_\/]+\.htm(l)?$/i }
        raise "No html was passed in." if html_file_pathes.blank?
        raise "Please only include one html file in the zip file." if html_file_pathes.size > 1
        html_file_pathes.first
      end

      # MailEngine::HtmlDocumentAssetsReplacer.process(mail_template, file_paths)
      def process mail_template, file_paths, hostname
        raise "Host should not include http://" if hostname =~ /^http:\/\//i

        # check if there is a html file
        html_file_path = check! file_paths

        # persist files into databases.
        other_file_paths = file_paths - Array.wrap(html_file_path)
        stored_file_objects = other_file_paths.map do |path|
          f = File.open(path)
          mail_template.mail_template_files.create :file => f, :size => File.size(f)
        end

        ### replace images and csses from the html document.
        # possible will use this in the future to take care of encoding problem:
        # doc = Nokogiri.XML('<foo><bar/><foo>', nil, 'EUC-JP')
        doc = Nokogiri::HTML(File.read(html_file_path))

        doc.css('img, link').each do |element|
          # FIXME seems will have the problem if have duplicated filename in different dir
          case
          when element.name == "link" && substitution_object = stored_file_objects.detect { |file_object| file_object.attributes["file"] == File.basename(element['href']) }
            element['href'] = "http://#{File.join(hostname, substitution_object.file.url)}"
          when element.name == "img" && substitution_object = stored_file_objects.detect { |file_object| file_object.attributes["file"] == File.basename(element['src']) }
            element['src'] = "http://#{File.join(hostname, substitution_object.file.url)}"
          end
        end

        doc.to_html
      end

      # replace the old filename in html by new filename
      def replace_resource_in_html html, original_filename, new_filename, resource_type
        # FIXME better to raise an error, return an unprocessed file maybe not good.
        return html if original_filename.blank? or new_filename.blank?
        doc = Nokogiri::HTML(html)
        doc.css('img, link').each do |element|
          # FIXME seems will have the problem if have duplicated filename in different dir
          next if element.name == "link" && element['href'].blank?
          next if element.name == "img" && element['src'].blank?

          case
          when element.name == "link" && get_resource_url(element['href'], resource_type) == original_filename
            element['href'] = element['href'].sub(original_filename, new_filename)
          when element.name == "img" && get_resource_url(element['src'], resource_type) == original_filename
            element['src'] = element['src'].sub(original_filename, new_filename)
          end
        end

        doc.to_html
      end

    private

      def get_resource_url(url, resource_type = :filename)
        resource_type = :filename unless [:filename, :url].include?(resource_type)
        resource_type == :filename ? File.basename(url) : url
      end
    end
  end
end