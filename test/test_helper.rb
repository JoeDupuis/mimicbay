ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "vcr"
require "webmock/minitest"
require "minitest/autorun"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false
  
  # Filter out the OpenAI API key
  openai_api_key = Rails.application.credentials.dig(:llm, :open_ai)
  if openai_api_key
    config.filter_sensitive_data('<OPENAI_API_KEY>') { openai_api_key }
    config.filter_sensitive_data('Bearer <OPENAI_API_KEY>') { "Bearer #{openai_api_key}" }
  end
  
  # Filter any sk- patterns that might appear in responses
  config.before_record do |interaction|
    interaction.response.body.gsub!(/sk-[a-zA-Z0-9_-]+/, '<OPENAI_API_KEY>')
  end
end

module ActiveSupport
  class TestCase
    include SessionTestHelper
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
