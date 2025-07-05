class ProcessLLMResponseJob < ApplicationJob
  queue_as :default

  def perform(session_id, model)
    session = GameConfigurationSession.find(session_id)

    adapter_class = LLM.adapter_for_model(model)
    raise ArgumentError, "Unknown model: #{model}" unless adapter_class

    adapter = adapter_class.new(model: model, user_id: session.game.user_id)
    tools = GameConfiguration::Tools::Base.all_definitions

    response = adapter.chat(session.messages, tools: tools)


    assistant_message = session.game_configuration_messages.create!(
      role: :assistant,
      content: response[:content],
      tool_calls: response[:tool_calls],
      model: model
    )

    if response[:tool_calls].present?
      process_tool_calls(session, response[:tool_calls], model)
    end
  rescue => e
    session.game_configuration_messages.create!(
      role: :assistant,
      content: "I encountered an error: #{e.message}"
    )
  end

  private

  def process_tool_calls(session, tool_calls, model)
    tool_calls.each do |tool_call|
      tool_class = GameConfiguration::Tools::Base.find_by_name(tool_call["name"])

      if tool_class
        tool = tool_class.new(session.game)
        result = tool.execute(tool_call["arguments"])

        session.game_configuration_messages.create!(
          role: :tool,
          content: result.to_json,
          tool_results: {
            "tool_use_id" => tool_call["id"],
            "tool_name" => tool_call["name"]
          }
        )
      else
        session.game_configuration_messages.create!(
          role: :tool,
          content: { error: "Unknown tool: #{tool_call["name"]}" }.to_json,
          tool_results: {
            "tool_use_id" => tool_call["id"],
            "tool_name" => tool_call["name"]
          }
        )
      end
    end

    # Continue the conversation after processing tool calls
    ProcessLLMResponseJob.perform_later(session.id, model)
  end
end
