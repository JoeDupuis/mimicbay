require "openai"

module LLM
  class OpenAi < Base
    def initialize(model: nil, user_id: nil)
      api_key = Rails.application.credentials.dig(:llm, :open_ai)
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

      # Skip tools for now to get basic functionality working

      response = client.responses.create(**parameters)
      parse_response(response)
    rescue => e
      Rails.logger.error "OpenAI API Error: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      raise "API Error: #{e.message}"
    end

    private

    def format_message_models(message_models)
      message_models.map do |msg|
        if msg.tool?
          {
            role: "tool",
            tool_call_id: msg.tool_results["tool_use_id"],
            content: msg.content
          }
        else
          formatted = {
            role: msg.role,
            content: msg.content
          }
          formatted[:tool_calls] = msg.tool_calls if msg.tool_calls.present?
          formatted
        end
      end
    end

    def format_messages(messages)
      messages.map do |message|
        case message[:role]
        when "tool"
          {
            role: "tool",
            tool_call_id: message[:tool_use_id] || message[:tool_call_id],
            content: message[:content]
          }
        else
          # Format message for responses API
          formatted = {
            role: message[:role],
            content: message[:content]
          }

          if message[:tool_calls]
            formatted[:tool_calls] = message[:tool_calls]
          end

          formatted
        end
      end
    end

    def format_tools_for_api(tools)
      tools.map do |tool|
        {
          type: :function,
          function: {
            name: tool[:name],
            description: tool[:description],
            parameters: tool[:parameters]
          }
        }
      end
    end

    def parse_response(response)
      Rails.logger.info "OpenAI Response Class: #{response.class.name}"
      Rails.logger.info "Response: #{response.inspect}"

      # The responses API returns output array
      if response.respond_to?(:output)
        output = response.output.first
        Rails.logger.info "Output: #{output.inspect}" if output

        return { role: "assistant", content: "" } unless output

        # Try different ways to get the content
        content = if output.respond_to?(:content) && output.content.is_a?(Array)
          # Content is an array of content objects, extract the text
          output.content.map { |c| c.respond_to?(:text) ? c.text : c.to_s }.join("\n")
        elsif output.respond_to?(:content)
          output.content
        elsif output.respond_to?(:text)
          output.text
        elsif output.is_a?(String)
          output
        else
          output.to_s
        end

        result = {
          role: "assistant",
          content: content || "[No content]"
        }
      else
        # Maybe response itself has the content
        result = {
          role: "assistant",
          content: response.to_s
        }
      end

      result
    end

    def parse_tool_calls(tool_calls)
      tool_calls.map do |tool_call|
        {
          id: tool_call.id,
          name: tool_call.function.name,
          arguments: JSON.parse(tool_call.function.arguments)
        }
      end
    end
  end
end
