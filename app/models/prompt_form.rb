class PromptForm < ApplicationRecord
  belongs_to :formable, polymorphic: true

  after_initialize do
    self.content ||= {}
  end

  def method_missing(method_name, *arguments, &block)
    method_name_string = method_name.to_s
    if method_name_string.end_with?('=')
      # Setter: Remove the '=' and set the value
      key = method_name_string.chomp('=')
      self.content[key] = arguments.first
    elsif self.content.has_key?(method_name_string)
      # Getter
      self.content[method_name_string]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name_string = method_name.to_s
    self.content.has_key?(method_name_string) || self.content.has_key?(method_name_string.chomp('=')) || super
  end
  
end
