require "openai"

class LLM::OpenAi < LLM
  def initialize(api_key: nil, model: nil, user_id: nil)
    api_key ||= Rails.application.credentials.dig(:llm, :open_ai)
    api_key ||= Rails.configuration.x.llm[:openai][:api_key] if Rails.configuration.x.llm[:openai].present?
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
      input: formatted_messages
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
    outputs = response.output

    return { role: "assistant", content: "" } if outputs.blank?

    result = { role: "assistant", content: "" }

    # Check if we have function calls
    function_calls = outputs.select { |output| output.type == :function_call }

    if function_calls.any?
      # Handle multiple tool calls
      result[:tool_calls] = function_calls.map do |output|
        {
          "id" => output.id,
          "name" => output.name,
          "arguments" => JSON.parse(output.arguments)
        }
      end
    else
      # Regular text response - combine all text outputs
      text_outputs = outputs.select { |output| output.type == :message }
      if text_outputs.any?
        # Combine all text content
        texts = text_outputs.flat_map { |output|
          output.content&.map(&:text) || []
        }.compact
        result[:content] = texts.join("")
      end
    end

    result
  end
end
