require "openai"

class LLM::OpenAi < LLM
  def initialize(api_key: nil, model: nil, user_id: nil)
    api_key ||= Rails.application.credentials.dig(:llm, :open_ai)
    super(api_key: api_key, model: model, user_id: user_id)
  end

  def chat(messages, tools: [])
    client = ::OpenAI::Client.new(api_key: api_key)

    # Format messages for the responses API
    # The responses API expects an array of message objects
    # Handle both ActiveRecord models and hash format
    formatted_messages = messages.first.respond_to?(:role) ? format_message_models(messages) : format_messages(messages)

    parameters = {
      model: model,
      input: formatted_messages,
      store: false
    }

    # Add user ID if available
    parameters[:user] = user_id.to_s if user_id

    # Add tools if provided
    parameters[:tools] = format_tools_for_api(tools) if tools.present?

    response = client.responses.create(**parameters)
    parse_response(response)
  rescue => e
    Rails.logger.error "OpenAI API Error: #{e.class.name} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise "API Error: #{e.message}"
  end

  private

  def format_message_models(message_models)
    formatted = []
    message_models.each do |msg|
      if msg.tool?
        formatted << {
          type: "function_call_output",
          call_id: msg.tool_results["tool_use_id"],
          output: msg.content
        }
      elsif msg.assistant? && msg.tool_calls.present?
        # Assistant message followed by function calls
        formatted << {
          role: msg.role,
          content: msg.content
        }
        msg.tool_calls.each do |tc|
          formatted << {
            type: "function_call",
            call_id: tc["id"],
            name: tc["name"],
            arguments: tc["arguments"].is_a?(String) ? tc["arguments"] : tc["arguments"].to_json
          }
        end
      else
        formatted << {
          role: msg.role,
          content: msg.content
        }
      end
    end
    formatted
  end

  def format_messages(messages)
    formatted = []
    messages.each do |message|
      case message[:role]
      when "tool"
        formatted << {
          type: "function_call_output",
          call_id: message[:tool_use_id] || message[:tool_call_id],
          output: message[:content]
        }
      when "assistant"
        formatted << {
          role: message[:role],
          content: message[:content]
        }
        # Add function calls as separate messages
        if message[:tool_calls].present?
          message[:tool_calls].each do |tc|
            formatted << {
              type: "function_call",
              call_id: tc["id"],
              name: tc["name"], 
              arguments: tc["arguments"].is_a?(String) ? tc["arguments"] : tc["arguments"].to_json
            }
          end
        end
      else
        # Format message for responses API
        formatted << {
          role: message[:role],
          content: message[:content]
        }
      end
    end
    formatted
  end

  def format_tools_for_api(tools)
    tools.map do |tool|
      {
        "type" => "function",
        "name" => tool["name"],
        "description" => tool["description"],
        "parameters" => tool["parameters"]
      }
    end
  end

  def parse_response(response)
    output = response.output&.first

    return { role: "assistant", content: "" } unless output

    result = { role: "assistant" }

    if output.type == :function_call
      # Handle tool calls
      result[:content] = ""
      result[:tool_calls] = [ {
        "id" => output.id,
        "name" => output.name,
        "arguments" => JSON.parse(output.arguments)
      } ]
    else
      # Regular text response - output is a message with content array
      content = output.content&.first
      result[:content] = content&.text || ""
    end

    result
  end
end
