class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @post, notice: "Comment added!"
    else
      redirect_to @post, alert: "Could not add comment."
    end
  end

  def destroy
    @post = Post.find(params[:post_id])
    @comment = @post.comments.find(params[:id])

    authorize! :destroy, @comment

    @comment.destroy
    redirect_to @post, notice: "Comment deleted."
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end
end
