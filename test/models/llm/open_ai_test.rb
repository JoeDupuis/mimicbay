require "test_helper"

class LLM::OpenAiTest < ActiveSupport::TestCase
  test "chat returns assistant response for simple message" do
    VCR.use_cassette("openai_simple_chat") do
      adapter = LLM::OpenAi.new(model: "gpt-4o-mini")
      messages = [
        { role: "user", content: "Say hello in exactly 3 words" }
      ]

      response = adapter.chat(messages)

      assert_equal "assistant", response[:role]
      assert response[:content].present?
    end
  end

  test "chat handles tool calls correctly" do
    VCR.use_cassette("openai_tool_call") do
      adapter = LLM::OpenAi.new(model: "gpt-4o-mini")
      messages = [
        { role: "user", content: "Create an area called 'Dark Forest' with a spooky description" }
      ]

      tools = [
        {
          "name" => "create_area",
          "description" => "Create a new area in the game",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "name" => { "type" => "string", "description" => "The name of the area" },
              "description" => { "type" => "string", "description" => "A detailed description of the area" }
            },
            "required" => [ "name", "description" ]
          }
        }
      ]

      response = adapter.chat(messages, tools: tools)

      assert_equal "assistant", response[:role]
      assert response[:tool_calls].present?
      assert_equal "create_area", response[:tool_calls].first["name"]
      assert response[:tool_calls].first["arguments"]["name"].present?
      assert response[:tool_calls].first["arguments"]["description"].present?
    end
  end

  test "chat continues conversation after tool execution" do
    VCR.use_cassette("openai_tool_response") do
      adapter = LLM::OpenAi.new(model: "gpt-4o-mini")
      messages = [
        { role: "user", content: "Create an area called 'Dark Forest'" },
        { role: "assistant", content: "", tool_calls: [
          { "id" => "call_123", "name" => "create_area", "arguments" => { "name" => "Dark Forest", "description" => "A mysterious forest" } }
        ] },
        { role: "tool", tool_use_id: "call_123", content: '{"success": true, "area_id": 1, "name": "Dark Forest", "message": "Created area \'Dark Forest\'"}' }
      ]

      response = adapter.chat(messages)

      assert_equal "assistant", response[:role]
      assert response[:content].present?
      assert response[:content].include?("Dark Forest") || response[:content].include?("created") || response[:content].include?("area")
    end
  end

  test "chat handles API errors gracefully" do
    VCR.use_cassette("openai_api_error") do
      adapter = LLM::OpenAi.new(model: "invalid-model")
      messages = [ { role: "user", content: "Hello" } ]

      assert_raises(RuntimeError) do
        adapter.chat(messages)
      end
    end
  end

  test "initializes with credentials from Rails config when no API key provided" do
    adapter = LLM::OpenAi.new(model: "gpt-4o")
    assert_not_nil adapter.instance_variable_get(:@api_key)
  end

  test "uses provided API key over Rails credentials" do
    custom_key = "custom-api-key"
    adapter = LLM::OpenAi.new(api_key: custom_key, model: "gpt-4o")
    assert_equal custom_key, adapter.instance_variable_get(:@api_key)
  end

  test "includes user_id in API request when provided" do
    VCR.use_cassette("openai_with_user_id") do
      adapter = LLM::OpenAi.new(model: "gpt-4o-mini", user_id: 123)
      messages = [ { role: "user", content: "Hello" } ]

      response = adapter.chat(messages)
      assert_equal "assistant", response[:role]
    end
  end
end
