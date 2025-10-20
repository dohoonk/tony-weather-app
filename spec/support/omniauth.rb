OmniAuth.config.test_mode = true

module OmniAuthHelpers
  def mock_google_auth(overrides = {})
    base = {
      provider: "google_oauth2",
      uid: "12345",
      info: {
        name: "Test User",
        email: "test.user@example.com",
        image: "https://example.com/avatar.png"
      },
      credentials: {
        token: "mock-token",
        refresh_token: "mock-refresh-token",
        expires_at: Time.now.to_i + 3600
      }
    }

    OmniAuth::AuthHash.new(base.deep_merge(overrides))
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers

  config.before do
    OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth
  end

  config.after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
