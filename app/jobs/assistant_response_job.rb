class AssistantResponseJob < ApplicationJob
  queue_as :default

  def perform(chat_message)
    chat_session = chat_message.chat_session
    assistant = chat_session.assistant
    service_session = chat_session.service_session

    # Create a new client instance
    client = OpenAI::Client.new
    if service_session.nil?
      openai_assistant = client.assistants.retrieve(id: assistant.external_id)
      # Create a new thread (see https://platform.openai.com/docs/api-reference/threads/createThread)
      response = client.threads.create
      thread_id = response["id"]
      # Create and associate new ServiceSession with ChatSession
      chat_session.create_service_session(external_id: thread_id)
    else
      # ServiceSession exists, use its external_id (thread_id)
      thread_id = service_session.external_id
    end

    p 'thread_id:' + thread_id

    # Add initial message from user (see https://platform.openai.com/docs/api-reference/messages/createMessage)
    client.messages.create(
      thread_id: thread_id,
      parameters: {
        role: "user", # Required for manually created messages
        content: chat_message.message_text
      })

    # Create run (will use instruction/model/tools from Assistant's definition)
    response = client.runs.create(thread_id: thread_id,
                                  parameters: {
                                    assistant_id: assistant.external_id
                                  })
    run_id = response['id']

    # Retrieve/poll Run to observe status
    while true do
      response = client.runs.retrieve(id: run_id, thread_id: thread_id)
      status = response['status']

      case status
      when 'queued', 'in_progress', 'cancelling'
        puts 'Sleeping'
        sleep 1 # Wait one second and poll again
      when 'completed'
        break # Exit loop and report result to user
      when 'requires_action'
        # Handle tool calls (see below)
      when 'cancelled', 'failed', 'expired'
        puts response['last_error'].inspect
        break # or `exit`
      else
        puts "Unknown status response: #{status}"
      end
    end

    # Retrieve the `run steps` for the run which link to the messages:
    run_steps = client.run_steps.list(thread_id: thread_id, run_id: run_id)
    new_message_ids = run_steps['data'].filter_map { |step|
      if step['type'] == 'message_creation'
        step.dig('step_details', "message_creation", "message_id")
      end # Ignore tool calls, because they don't create new messages.
    }

    # Retrieve the individual messages
    new_messages = new_message_ids.map { |msg_id|
      client.messages.retrieve(id: msg_id, thread_id: thread_id)
    }

    # Find the actual response text in the content array of the messages
    new_messages.each { |msg|
      msg['content'].each { |content_item|
        case content_item['type']
        when 'text'
          new_message =  content_item.dig('text', 'value')
          assistant_message = chat_session.chat_messages.create(message_text: new_message, sender_role: ChatMessage::SENDER_ROLE_ASSISTANT)

          p assistant_message

          # Broadcast the new message to the chat session's stream
          Turbo::StreamsChannel.broadcast_append_to(
            "chat_session_#{chat_session.anonymous_user_id}", # Target stream
            target: "messages",
            partial: "chat/message",
            locals: { message: assistant_message }
          )

        when 'image_file'
          # Use File endpoint to retrieve file contents via id
          id = content_item.dig('image_file', 'file_id')
        end
      }
    }
  end
end
