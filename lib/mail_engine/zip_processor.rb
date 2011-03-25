module MailEngine
  class ZipProcessor
    class << self
      # Usage:
      # MailEngine::ZipProcessor.extract_all_files(path, ["css", "jpg", "gif"]) do |file_path|
      #   Image.create :file => File.open(file_path)
      # end
      #
      # Params:
      # zip_file_path => /path/to/your/zip_file
      # needed_exts => ['jpg', 'jpeg', 'css']
      #
      # Result:
      # the first item of array is file paths you needed and extracted from zip file.
      # the second item is the unzip path.
      #
      # [
      #   [
      #     "/Volumes/documents/projects/work/mail_engine/test/dummy/tmp/zip_processor_tmp_dir/compress_by_dir9671920/compress_by_file/css/example.css",
      #     "/Volumes/documents/projects/work/mail_engine/test/dummy/tmp/zip_processor_tmp_dir/compress_by_dir9671920/compress_by_file/images/logo.png",
      #     "/Volumes/documents/projects/work/mail_engine/test/dummy/tmp/zip_processor_tmp_dir/compress_by_dir9671920/compress_by_file/index.html"
      #   ],
      #   "/Volumes/documents/projects/work/mail_engine/test/dummy/tmp/zip_processor_tmp_dir/compress_by_dir9671920"
      # ]
      def extract_all_files(zip_file_path, needed_exts)
        return unless zip_file_path =~ /\.zip$/i

        # Create zip_processor_tmp_dir dir
        zip_processor_tmp_dir = File.join(Rails.root, 'tmp', 'zip_processor_tmp_dir')
        unless File.exist?(zip_processor_tmp_dir)
          FileUtils.mkdir_p(zip_processor_tmp_dir)
        end

        file_fullname = File.basename(zip_file_path)
        filename = file_fullname.sub(/.zip$/, "")
        unzip_path = File.join(zip_processor_tmp_dir, "#{filename}#{rand(10000000)}")

        unzip_result = system("unzip #{zip_file_path} -d #{unzip_path} > /dev/null")
        unzip_result = unzip_result && $?.exitstatus == 0

        return unless unzip_result

        file_ext_param_str = needed_exts.map {|ext| "-iname '*.#{ext}'" }.join(" -o ")

        result_list_string = `find #{unzip_path} #{file_ext_param_str}`
        result_list = result_list_string.split("\n")

        if block_given?
          result_list.each do |file_path|
            yield file_path
          end
          # remove the unzip tmp files.
          system("rm -rf #{unzip_path}")
        else
          [result_list, unzip_path]
        end
      end
    end
  end
end