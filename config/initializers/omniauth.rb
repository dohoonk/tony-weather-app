Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch("GOOGLE_CLIENT_ID"),
           ENV.fetch("GOOGLE_CLIENT_SECRET"),
           {
             prompt: "select_account",
             image_aspect_ratio: "square",
             image_size: 50,
             scope: "email,profile"
           }
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = %i[get]
OmniAuth.config.silence_get_warning = true