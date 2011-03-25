FactoryGirl.define do
  factory :user do |u|
    email "m@theplant.jp"
    firstname "Michael"
    lastname "He"
  end

  factory :footer_partial, :class => MailEngine::TemplatePartial do |t|
    placeholder_name "footer"
    association :partial, :factory => :partial_template
  end

  factory :partial_template, :class => MailEngine::MailTemplate do |t|
    name "New Job"
    path "user_mailer/notify"
    locale "en"
    handler "liquid"
    body "=== partial ==="
    partial true
  end

  factory :zip_mail_template_with_footer, :class => MailEngine::MailTemplate do |t|
    name "New Job"
    path "user_mailer/notify"
    subject "mail template title"
    # format "html" # can't set format
    locale "en"
    handler "liquid"
    layout "only_footer"
    partial false
    for_marketing false
    zip_file File.open(File.join(Rails.root, '../..', 'test', 'fixtures', 'files', 'compress_by_file.zip'))
    create_by_upload true
    template_partials { [FactoryGirl.create(:footer_partial)] }
  end

  factory :system_mail_template, :class => MailEngine::MailTemplate do |t|
    name "New Job"
    path "user_mailer/notify"
    subject "mail template title"
    # format "html" # can't set format
    locale "en"
    handler "liquid"
    body "latest jobs mail."
    layout "none"
    partial false
    for_marketing false
  end

  factory :system_mail_template_with_footer, :class => MailEngine::MailTemplate do |t|
    name "New Job"
    path "user_mailer/notify"
    subject "mail template title"
    # format "html" # can't set format
    locale "en"
    handler "liquid"
    body "latest jobs mail."
    layout "only_footer"
    partial false
    for_marketing false
    template_partials { [FactoryGirl.create(:footer_partial)] }
  end

  factory :dirzip_mail_template, :class => MailEngine::MailTemplate do |t|
    name "New Job"
    path "user_mailer/notify"
    subject "mail template title"
    # format "html" # can't set format
    locale "en"
    handler "liquid"
    layout "none"
    partial false
    for_marketing false
    zip_file File.open(File.join(Rails.root, '../..', 'test', 'fixtures', 'files', 'compress_by_dir.zip'))
    create_by_upload true
  end

  factory :filezip_mail_template, :class => MailEngine::MailTemplate do |t|
    name "New Job"
    path "user_mailer/notify"
    subject "mail template title"
    # format "html" # can't set format
    locale "en"
    handler "liquid"
    layout "none"
    partial false
    for_marketing false
    zip_file File.open(File.join(Rails.root, '../..', 'test', 'fixtures', 'files', 'compress_by_file.zip'))
    create_by_upload true
  end

  factory :marketing_mail_template, :class => MailEngine::MailTemplate do |t|
    name "New Job Newsletter"
    path "new_jobs"
    subject "new job mail title"
    # format "html" # can't set format
    locale "en"
    handler "liquid"
    body "latest jobs mail."
    layout "none"
    partial false
    for_marketing true
  end

  factory :mail_schedule, :class => MailEngine::MailSchedule do
    name "New Data"
    association :mail_template, :factory => :marketing_mail_template, :format => "html"
    # default_locale 'en'
    user_group "all"
    count 0
    sent_count 0
    period "daily"
    payload "firstname,lastname"
    first_send_at Time.now
  end
end