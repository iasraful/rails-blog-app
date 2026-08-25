require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user and start session" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          email_address: "signup_test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
    assert_equal "Successfully signed up! Welcome to Blog App.", flash[:notice]
  end

  test "should fail to create user with invalid parameters" do
    assert_no_difference("User.count") do
      post users_url, params: {
        user: {
          email_address: "invalid-email",
          password: "123",
          password_confirmation: "456"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
