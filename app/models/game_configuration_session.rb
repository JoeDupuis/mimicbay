class GameConfigurationSession < ApplicationRecord
  belongs_to :game
  has_many :game_configuration_messages, dependent: :destroy

  def messages
    game_configuration_messages.order(:created_at)
  end

  def prompt(content, model: nil)
    raise "No model specified" if model.blank?

    adapter_class = LLM.adapter_for_model(model)
    raise "Unknown model: #{model}" unless adapter_class

    game_configuration_messages.create!(role: :user, content: content)

    adapter = adapter_class.new(model: model, user_id: game.user_id)
    messages = format_messages_for_llm
    tools = GameConfiguration::Tools::Base.all_definitions

    response = adapter.chat(messages, tools: tools)

    assistant_message = game_configuration_messages.create!(
      role: :assistant,
      content: response[:content],
      tool_calls: response[:tool_calls],
      model: model
    )

    if response[:tool_calls].present?
      process_tool_calls(response[:tool_calls], assistant_message, model: model)
    end
  rescue => e
    game_configuration_messages.create!(
      role: :assistant,
      content: "I encountered an error: #{e.message}"
    )
  end

  private

  def format_messages_for_llm
    system_message = {
      role: "system",
      content: "You are a helpful game configuration assistant. Help the user create areas and characters for their tabletop RPG game. Use the provided tools to create, update, list, and delete game entities based on the user's descriptions."
    }

    messages = [ system_message ]

    self.messages.each do |msg|
      if msg.tool?
        messages << {
          role: "tool",
          content: msg.content,
          tool_use_id: msg.tool_results["tool_use_id"]
        }
      else
        formatted_msg = {
          role: msg.role,
          content: msg.content
        }
        formatted_msg[:tool_calls] = msg.tool_calls if msg.tool_calls.present?
        messages << formatted_msg
      end
    end

    messages
  end

  def process_tool_calls(tool_calls, assistant_message, model: nil)
    tool_calls.each do |tool_call|
      tool_class = GameConfiguration::Tools::Base.find_by_name(tool_call["name"])

      if tool_class
        tool = tool_class.new(game)
        result = tool.execute(tool_call["arguments"])

        game_configuration_messages.create!(
          role: :tool,
          content: result.to_json,
          tool_results: {
            "tool_use_id" => tool_call["id"],
            "tool_name" => tool_call["name"]
          }
        )
      else
        game_configuration_messages.create!(
          role: :tool,
          content: { error: "Unknown tool: #{tool_call["name"]}" }.to_json,
          tool_results: {
            "tool_use_id" => tool_call["id"],
            "tool_name" => tool_call["name"]
          }
        )
      end
    end

    continue_conversation_after_tools(model: model)
  end

  def continue_conversation_after_tools(model: nil)
    adapter_class = LLM.adapter_for_model(model)
    raise "Unknown model: #{model}" unless adapter_class

    adapter = adapter_class.new(model: model, user_id: game.user_id)
    messages = format_messages_for_llm
    tools = GameConfiguration::Tools::Base.all_definitions

    response = adapter.chat(messages, tools: tools)

    game_configuration_messages.create!(
      role: :assistant,
      content: response[:content],
      tool_calls: response[:tool_calls],
      model: model
    )

    if response[:tool_calls].present?
      process_tool_calls(response[:tool_calls], nil, model: model)
    end
  end
end
