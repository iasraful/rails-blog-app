class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  rescue_from CanCan::AccessDenied do |_exception|
    respond_to do |format|
      format.html { redirect_back_or_to root_path, alert: "Only Admin can perform this action." }
      format.json { render json: { error: "Only Admin can perform this action." }, status: :forbidden }
    end
  end

  private

  def current_user
    Current.user
  end
end
