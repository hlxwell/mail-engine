require 'test_helper'

class MailEngine::MailTemplateFileTest < ActiveSupport::TestCase
  context "Mail template file" do
    setup do
      @template = FactoryGirl.create(:dirzip_mail_template, :format => "html")
    end

    context "after updated" do
      setup do
        @template.mail_template_files.last.update_attributes :file => File.open(File.join(Rails.root, '../..', 'test', 'fixtures', 'files', 'image.png'))
      end

      should "update the file url in the mail template html" do
        @template.reload
        assert @template.body.include?(@template.mail_template_files.last.file.url)
      end
    end
  end

end