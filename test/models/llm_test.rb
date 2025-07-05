require "test_helper"

class LLMTest < ActiveSupport::TestCase
  test "adapter_for_model returns OpenAi adapter for GPT models" do
    assert_equal LLM::OpenAi, LLM.adapter_for_model("gpt-4.1")
    assert_equal LLM::OpenAi, LLM.adapter_for_model("gpt-4o")
    assert_equal LLM::OpenAi, LLM.adapter_for_model("gpt-4o-mini")
  end

  test "adapter_for_model returns nil for unknown model" do
    assert_nil LLM.adapter_for_model("unknown-model")
    assert_nil LLM.adapter_for_model("")
    assert_nil LLM.adapter_for_model(nil)
  end

  test "find_model returns correct model info" do
    model = LLM.find_model("gpt-4.1")
    assert_equal "gpt-4.1", model[:id]
    assert_equal "GPT-4.1", model[:name]
    assert_equal "OpenAi", model[:adapter]
  end

  test "find_model returns nil for unknown id" do
    assert_nil LLM.find_model("unknown-id")
    assert_nil LLM.find_model("")
    assert_nil LLM.find_model(nil)
  end

  test "MODELS constant contains expected models" do
    model_ids = LLM::MODELS.map { |m| m[:id] }
    assert_includes model_ids, "gpt-4.1"
    assert_includes model_ids, "gpt-4o"
    assert_includes model_ids, "gpt-4o-mini"
    assert_includes model_ids, "gpt-3.5-turbo"
  end
end
