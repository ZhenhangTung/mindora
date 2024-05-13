class PromptForm < ApplicationRecord
  belongs_to :formable, polymorphic: true

  after_initialize do
    self.content ||= {}
  end

  # 设置和获取 ideas
  def ideas
    content['ideas']
  end

  def ideas=(value)
    self.content ||= {}
    self.content['ideas'] = value
  end

  # 设置和获取 challenges
  def challenges
    self.content ||= {}
    content['challenges']
  end

  def challenges=(value)
    self.content['challenges'] = value
  end
end
