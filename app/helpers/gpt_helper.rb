module GptHelper
  def gpt35_deployment_uri
    ENV["AZURE_OPENAI_URI"].gsub('gpt-4', 'gpt-35-turbo')
  end
end
