require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @admin = users(:admin)
    @post = posts(:one)
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get new" do
    sign_in_as(@user)
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    sign_in_as(@user)
    assert_difference("Post.count") do
      post posts_url, params: { post: { content: @post.content, title: @post.title } }
    end

    assert_redirected_to post_url(Post.last)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    sign_in_as(@user)
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    sign_in_as(@user)
    patch post_url(@post), params: { post: { content: @post.content, title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "should destroy post" do
    sign_in_as(@user)
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end

  test "should redirect unauthorized destroy with alert message" do
    unauthorized_user = users(:two)
    sign_in_as(unauthorized_user)

    assert_no_difference("Post.count") do
      delete post_url(@post)
    end

    assert_redirected_to root_url
    assert_equal "Only Admin can perform this action.", flash[:alert]
  end
end
