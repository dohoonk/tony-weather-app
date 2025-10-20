class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    session[:user] = {
      uid: auth.uid,
      name: auth.info.name,
      email: auth.info.email,
      image: auth.info.image
    }

    redirect_to weather_path, notice: "Signed in successfully."
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end

  def failure
    redirect_to root_path, alert: "Authentication failed."
  end
end
