class ProcessUserJourneyMapConversationsJob < ApplicationJob
  queue_as :default

  def perform(user_journey_map_id)
    user_journey_map = UserJourneyMap.includes(:prompt_forms).find_by(id: user_journey_map_id)
    return unless user_journey_map

    prompt_form = user_journey_map.prompt_forms.first
    session = user_journey_map.create_session(sessionable: user_journey_map)
    content = "产品想法：#{prompt_form.ideas}\n当下挑战：#{prompt_form.challenges}"
    # session.store_human_message()

  end

  private


end
