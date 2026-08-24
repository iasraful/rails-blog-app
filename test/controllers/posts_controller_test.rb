require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @editor = users(:editor)
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

  test "owner should get edit" do
    sign_in_as(@user)
    get edit_post_url(@post)
    assert_response :success
  end

  test "editor should get edit" do
    sign_in_as(@editor)
    get edit_post_url(@post)
    assert_response :success
  end

  test "admin should get edit" do
    sign_in_as(@admin)
    get edit_post_url(@post)
    assert_response :success
  end

  test "owner should update post" do
    sign_in_as(@user)
    patch post_url(@post), params: { post: { content: @post.content, title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "editor should update post" do
    sign_in_as(@editor)
    patch post_url(@post), params: { post: { content: @post.content, title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "owner should destroy post" do
    sign_in_as(@user)
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end

  test "admin should destroy post" do
    sign_in_as(@admin)
    assert_difference("Post.count", -1) do
      delete post_url(@post)
   end

    assert_redirected_to posts_url
  end

  test "should redirect unauthorized edit for non-owner user with alert message" do
    sign_in_as(@other_user)
    get edit_post_url(@post)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should redirect unauthorized update for non-owner user with alert message" do
    sign_in_as(@other_user)
    patch post_url(@post), params: { post: { content: "New Content", title: "New Title" } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should redirect unauthorized destroy for non-owner user with alert message" do
    sign_in_as(@other_user)

    assert_no_difference("Post.count") do
      delete post_url(@post)
   end

    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
