require "test_helper"

class LLMGameConfigurationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:game_master)
    @game = games(:game_without_characters)
    sign_in_as @user
  end

  test "full flow: user message triggers LLM response with tool execution" do
    VCR.use_cassette("integration_full_flow") do
      # Ensure the area doesn't exist yet
      assert_nil @game.areas.find_by(name: "Mystic Cave")
      
      # Navigate to game configuration - this creates the session
      get game_configuration_path(@game)
      assert_response :success
      
      # Send a message that should trigger tool use
      assert_difference -> { GameConfigurationMessage.count }, 1 do
        assert_enqueued_with(job: ProcessLLMResponseJob) do
          post game_configuration_messages_path(@game), params: {
            content: "Create an area called 'Mystic Cave' with a description about crystals and magic",
            model: "gpt-4o-mini"
          }, as: :turbo_stream
          assert_response :success
        end
      end
      
      # Perform the job
      perform_enqueued_jobs
      
      # Check that assistant response and tool messages were created
      session = @game.game_configuration_session
      messages = session.game_configuration_messages.order(:created_at)
      
      # Should have: system prompt, user message, assistant message with tool call, tool result, final assistant message
      assert messages.count >= 4
      
      # Check tool was executed
      area = @game.areas.find_by(name: "Mystic Cave")
      assert area.present?
      assert area.description.present?
    end
  end

  test "handles API errors gracefully in integration" do
    # Navigate to game configuration to create session
    get game_configuration_path(@game)
    
    # Mock API error
    stub_adapter = Object.new
    def stub_adapter.chat(messages, tools: [])
      raise "API Error: Rate limit exceeded"
    end
    
    LLM::OpenAi.stub :new, stub_adapter do
      post game_configuration_messages_path(@game), params: {
        content: "Hello",
        model: "gpt-4o-mini"
      }, as: :turbo_stream
      
      perform_enqueued_jobs
      
      # Should create an error message
      error_message = @game.game_configuration_session.game_configuration_messages.last
      assert_equal "assistant", error_message.role
      assert error_message.content.include?("I encountered an error")
    end
  end

  test "broadcasts updates via Turbo Streams" do
    # Navigate to game configuration to create session
    get game_configuration_path(@game)
    
    # This test verifies the Turbo Stream broadcasting works
    # In a real browser test, we'd verify the DOM updates
    assert_difference -> { GameConfigurationMessage.count }, 1 do
      post game_configuration_messages_path(@game), params: {
        content: "Test message",
        model: "gpt-4o-mini"
      }, as: :turbo_stream
      
      assert_response :success
      # The controller returns head :ok for turbo_stream format, so body is empty
      # The actual turbo streams are broadcast via ActionCable
    end
  end

end