class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user, :signed_in?

  private

  def current_user
    return unless session[:user]

    @current_user ||= session[:user].with_indifferent_access
  end

  def signed_in?
    current_user.present?
  end

  def require_login
    return if signed_in?

    redirect_to "/auth/google_oauth2"
  end
end
