module MailEngine
  Rails.application.routes.draw do
    # if not loaded config should not mount it.
    if mount_at = MailEngine::Base.current_config["mount_at"]
      scope mount_at, :module => :mail_engine do
        match '/', :controller => "dashboard", :action => "index", :as => :mail_engine_dashboard

        resources :mail_templates do
          member do
            get :duplicate
            put :duplicate
            get :preview
            post :preview
            get :body
            post :body
            post :send_test_mail
          end

          collection do
            # used before mail template been saved
            post :preview

            get :import
            post :import_from_files
            get :get_existed_subject
            get :new_by_upload
            post :create_by_upload
            post :partial_options
          end

          resources :mail_template_files
        end

        resources :mail_schedules do
          member do
            post :start
            post :stop
            post :send_test_mail
          end
        end

        resources :reports do
          collection do
            get :chart
          end
        end

        resources :mail_logs
      end
    end # end if
  end
end