class Games::ConfigurationsController < ApplicationController
  before_action :set_game
  before_action :ensure_game_creating
  before_action :set_or_create_session

  def show
    @messages = @session.messages.includes(:game_configuration_session)
    if @game.llm_adapter.present?
      adapter = @game.llm_adapter_instance
      @available_models = adapter.available_models
      @default_model = adapter.default_model
    end
  end

  def available_models
    adapter_class_name = params[:adapter]
    return render json: { models: [], default: nil } unless adapter_class_name.present?

    # Whitelist of allowed adapters to prevent arbitrary code execution
    allowed_adapters = [ "LLM::OpenAi" ]
    unless allowed_adapters.include?(adapter_class_name)
      return render json: { models: [], default: nil }
    end

    begin
      adapter_class = adapter_class_name.constantize
      key_name = :open_ai
      api_key = Rails.application.credentials.dig(:llm, key_name)
      adapter = adapter_class.new(api_key: api_key)

      render json: {
        models: adapter.available_models,
        default: adapter.default_model
      }
    rescue NameError
      render json: { models: [], default: nil }
    end
  end

  def create_message
    user_content = params[:content]
    model = params[:model]

    @session.game_configuration_messages.create!(
      role: "user",
      content: user_content
    )

    process_llm_response(user_content, model: model)

    # Set up models for the turbo stream response
    if @game.llm_adapter.present?
      adapter = @game.llm_adapter_instance
      @available_models = adapter.available_models
      @default_model = adapter.default_model
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to game_configuration_path(@game) }
    end
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def ensure_game_creating
    redirect_to game_path(@game), alert: "Game configuration is only available during game creation" unless @game.creating?
  end

  def set_or_create_session
    @session = @game.game_configuration_session || @game.create_game_configuration_session!
  end

  def process_llm_response(user_content, model: nil)
    return unless @game.llm_adapter.present?

    adapter = @game.llm_adapter_instance(model: model)
    messages = format_messages_for_llm
    tools = GameConfiguration::Tools::Base.all_definitions

    response = adapter.chat(messages, tools: tools)

    assistant_message = @session.game_configuration_messages.create!(
      role: "assistant",
      content: response[:content],
      tool_calls: response[:tool_calls],
      model: model
    )

    if response[:tool_calls].present?
      process_tool_calls(response[:tool_calls], assistant_message, model: model)
    end
  rescue => e
    @session.game_configuration_messages.create!(
      role: "assistant",
      content: "I encountered an error: #{e.message}"
    )
  end

  def format_messages_for_llm
    system_message = {
      role: "system",
      content: "You are a helpful game configuration assistant. Help the user create areas and characters for their tabletop RPG game. Use the provided tools to create, update, list, and delete game entities based on the user's descriptions."
    }

    messages = [ system_message ]

    @session.messages.each do |msg|
      if msg.role == "tool"
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
        tool = tool_class.new(@game)
        result = tool.execute(tool_call["arguments"])

        @session.game_configuration_messages.create!(
          role: "tool",
          content: result.to_json,
          tool_results: {
            "tool_use_id" => tool_call["id"],
            "tool_name" => tool_call["name"]
          }
        )
      else
        @session.game_configuration_messages.create!(
          role: "tool",
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
    adapter = @game.llm_adapter_instance(model: model)
    messages = format_messages_for_llm
    tools = GameConfiguration::Tools::Base.all_definitions

    response = adapter.chat(messages, tools: tools)

    @session.game_configuration_messages.create!(
      role: "assistant",
      content: response[:content],
      tool_calls: response[:tool_calls],
      model: model
    )

    if response[:tool_calls].present?
      process_tool_calls(response[:tool_calls], nil, model: model)
    end
  end
end
