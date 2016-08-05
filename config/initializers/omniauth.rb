OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FB_APP_KEY'], ENV['FB_SECRET_KEY']
  provider :twitter, ENV['TW_APP_KEY'], ENV['TW_SECRET_KEY']
end