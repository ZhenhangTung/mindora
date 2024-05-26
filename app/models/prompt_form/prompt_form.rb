module PromptForm
  class PromptForm < ApplicationRecord
    belongs_to :formable, polymorphic: true

    after_initialize do
      self.content ||= {}
    end

    def self.define_fields(*fields)
      @fields ||= []
      @fields += fields

      fields.each do |field|
        define_method(field) do
          self.content[field.to_s]
        end

        define_method("#{field}=") do |value|
          self.content[field.to_s] = value
        end
      end
    end

    def attributes
      super.merge(self.class.fields.each_with_object({}) do |field, hash|
        hash[field.to_s] = send(field)
      end)
    end

    class << self
      attr_accessor :fields
    end

    validates :type, presence: true, inclusion: { in: %w(PromptForm::UserJourneyMap) }
  end
end
