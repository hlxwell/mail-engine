require 'test_helper'

class MailEngine::MailTemplateTest < ActiveSupport::TestCase

  def self.should_process_file
    should "be able to extract files" do
      assert_equal 2, @template.mail_template_files.size
      @template.mail_template_files.map {|f| f.file.url}.each do |template_file_url|
        assert @template.body.include?(template_file_url), "don't include #{template_file_url}"
      end
    end

    should "remove the temp file after created" do
      assert_equal [".", ".."], Dir.entries(File.join(Rails.root, "tmp", "zip_processor_tmp_dir"))
    end
  end

  context "Template class" do
    setup do
    end
    should "be able to get_subject_from_bother_template"
    should "be able to import templates from exist system"
  end

  context "A Template" do
    setup do
      @template = FactoryGirl.create(:system_mail_template_with_footer, :format => "html")
    end

    should "have a correct full path" do
      assert_equal "user_mailer/notify.en.html.liquid", @template.full_path
    end

    should "have a correct template name" do
      assert_equal "notify", @template.template_name
    end

    should "have a correct filename" do
      assert_equal "user_mailer/notify", @template.filename
      @template.partial = true
      assert_equal "user_mailer/_notify", @template.filename
    end

    context "has locale, regardless of the format" do
      setup do
        @template_text = FactoryGirl.build(:system_mail_template, :format => "text")
      end

      should "has the same subject" do
        assert_equal @template.subject, @template_text.subject
        @template_text.subject = "xxx"
        assert @template_text.save
        @template.reload
        @template_text.reload
        assert_equal @template.subject, @template_text.subject
      end
    end

    should "know if partial_in_use?" do
      assert_equal 1, @template.partials.count
      assert @template.partials.first.partial_in_use?
    end

    should "be able to get missing variations" do
      assert_equal 4, @template.variations.count # all normal templates
      assert_equal 4, @template.variations(true).count # all partials
      assert_equal 3, @template.variations.delete_if {|v| v.persisted? }.size

      variations = @template.variations.map { |v|
        [v.locale, v.format]
      }.sort

      assert_equal [["en", "html"], ["en", "text"], ["zh", "html"], ["zh", "text"]], variations
    end
  end

  context "Create by upload" do
    setup do
      `rm -rf #{File.join(Rails.root, "tmp", "zip_processor_tmp_dir")}`
    end

    context "a dirzip file" do
      setup do
        @template = FactoryGirl.create(:dirzip_mail_template, :format => "html")
      end
      should_process_file
    end

    context "a filezip file" do
      setup do
        @template = FactoryGirl.create(:filezip_mail_template, :format => "html")
      end
      should_process_file
    end
  end

  context "Template duplication" do
    setup do
      clear_database
      @zipmail_template = FactoryGirl.create(:filezip_mail_template, :format => "html")
      @clone_template = @zipmail_template.duplicate(:path => "user_mailer/notify_clone")
    end

    should "two template should be different" do
      assert_not_equal @clone_template, @zipmail_template
    end

    ### not works in test
    # should "clone mail template files" do
    #   assert_equal @clone_template.mail_template_files.count, @zipmail_template.mail_template_files.count, "clone template has different files with original one."
    # end
    #
    # should "has the same files" do
    #   @clone_template.mail_template_files.each_with_index do |f, index|
    #     assert_equal File.basename(f.file.path), @zipmail_template.mail_template_files[index].try(:attributes).try(:[], "file")
    #   end
    # end

    should "clone partial relation records" do
      assert_equal @clone_template.partials.count, @zipmail_template.partials.count
    end
  end

end