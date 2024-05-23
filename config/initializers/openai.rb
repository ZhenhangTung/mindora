# frozen_string_literal: true
OpenAI.configure do |config|
    config.access_token = ENV["AZURE_EASTUS2_OPENAI_API_KEY"]
    config.uri_base = ENV["AZURE_EASTUS2_OPENAI_URI"]
    config.api_type = :azure
    config.api_version = "2024-02-01"
end
