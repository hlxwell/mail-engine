require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "user" do
    setup do
      @user = Factory(:user)
    end

    context "after applied acts_as_mail_receiver" do
      should "has payload_columns class attr" do
        assert_equal User.payload_columns.sort, ["firstname", "lastname"].sort
      end

      should "has groups class attr" do
        assert_equal User.groups.sort, ["all", "english_users", "chinese_users"].sort
      end
    end

  end
end