require "test_helper"

class ProcessLLMResponseJobTest < ActiveJob::TestCase
  setup do
    @game = games(:game_without_characters)
    @session = @game.create_game_configuration_session!
  end

  test "creates assistant message from LLM response" do
    # Create a stub adapter that returns a simple response
    stub_adapter = Object.new
    def stub_adapter.chat(messages, tools: [])
      { role: "assistant", content: "I'll help you create your game world!" }
    end
    
    LLM::OpenAi.stub :new, stub_adapter do
        assert_difference -> { @session.game_configuration_messages.count }, 1 do
          ProcessLLMResponseJob.perform_now(@session.id, "gpt-4o-mini")
        end
    end
    
    message = @session.game_configuration_messages.last
    assert_equal "assistant", message.role
    assert_equal "I'll help you create your game world!", message.content
    assert_nil message.tool_calls
  end

  test "handles tool calls from LLM" do
    # Create a stub adapter that returns a tool call response
    stub_adapter = Object.new
    def stub_adapter.chat(messages, tools: [])
      {
        role: "assistant",
        content: "",
        tool_calls: [{
          "id" => "call_123",
          "name" => "create_area",
          "arguments" => { "name" => "Dark Forest", "description" => "A spooky forest" }
        }]
      }
    end
    
    LLM::OpenAi.stub :new, stub_adapter do
        assert_difference -> { @session.game_configuration_messages.count }, 2 do
          assert_difference -> { @game.areas.count }, 1 do
            assert_enqueued_with(job: ProcessLLMResponseJob) do
              ProcessLLMResponseJob.perform_now(@session.id, "gpt-4o-mini")
            end
          end
        end
    end
    
    # Check assistant message with tool call
    assistant_message = @session.game_configuration_messages.where(role: "assistant").last
    assert_equal [{
      "id" => "call_123",
      "name" => "create_area",
      "arguments" => { "name" => "Dark Forest", "description" => "A spooky forest" }
    }], assistant_message.tool_calls
    
    # Check tool response message
    tool_message = @session.game_configuration_messages.where(role: "tool").last
    assert tool_message.content.include?("success")
    assert_equal "call_123", tool_message.tool_results["tool_use_id"]
    assert_equal "create_area", tool_message.tool_results["tool_name"]
    
    # Check area was created
    area = @game.areas.last
    assert_equal "Dark Forest", area.name
    assert_equal "A spooky forest", area.description
  end

  test "handles unknown tool gracefully" do
    stub_adapter = Object.new
    def stub_adapter.chat(messages, tools: [])
      {
        role: "assistant",
        content: "",
        tool_calls: [{
          "id" => "call_456",
          "name" => "unknown_tool",
          "arguments" => { "param" => "value" }
        }]
      }
    end
    
    LLM::OpenAi.stub :new, stub_adapter do
        assert_difference -> { @session.game_configuration_messages.count }, 2 do
          assert_enqueued_with(job: ProcessLLMResponseJob) do
            ProcessLLMResponseJob.perform_now(@session.id, "gpt-4o-mini")
          end
        end
    end
    
    tool_message = @session.game_configuration_messages.where(role: "tool").last
    assert tool_message.content.include?("Unknown tool: unknown_tool")
  end

  test "handles API errors gracefully" do
    stub_adapter = Object.new
    def stub_adapter.chat(messages, tools: [])
      raise "API Error: Connection failed"
    end
    
    LLM::OpenAi.stub :new, stub_adapter do
        assert_difference -> { @session.game_configuration_messages.count }, 1 do
          ProcessLLMResponseJob.perform_now(@session.id, "gpt-4o-mini")
        end
    end
    
    message = @session.game_configuration_messages.last
    assert_equal "assistant", message.role
    assert message.content.include?("I encountered an error")
    assert message.content.include?("API Error: Connection failed")
  end

  test "returns early if adapter not found" do
    assert_no_difference -> { @session.game_configuration_messages.count } do
      ProcessLLMResponseJob.perform_now(@session.id, "unknown-model")
    end
  end

  test "includes existing messages in conversation context" do
    # Add some existing messages
    @session.game_configuration_messages.create!(role: "user", content: "Create a forest area")
    @session.game_configuration_messages.create!(role: "assistant", content: "I'll create a forest area for you")
    
    # Create a stub that verifies it receives the right messages
    messages_received = nil
    stub_adapter = Object.new
    stub_adapter.define_singleton_method(:chat) do |messages, tools: []|
      messages_received = messages
      { role: "assistant", content: "Forest created!" }
    end
    
    LLM::OpenAi.stub :new, stub_adapter do
        ProcessLLMResponseJob.perform_now(@session.id, "gpt-4o-mini")
    end
    
    # Verify the messages array included existing messages
    assert_equal 4, messages_received.count # initial system + system + user + assistant
    assert messages_received.any? { |m| m.content == "Create a forest area" }
    assert messages_received.any? { |m| m.content == "I'll create a forest area for you" }
  end
end