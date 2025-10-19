require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<WEATHERAPI_KEY>") { ENV.fetch("WEATHERAPI_KEY", "test-key") }
  config.ignore_localhost = true
end
