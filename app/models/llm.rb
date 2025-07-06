class LLM
  MODELS = [
    { id: "gpt-4.1", name: "GPT-4.1", adapter: "OpenAi" },
    { id: "gpt-4.1-mini", name: "GPT-4.1 Mini", adapter: "OpenAi" },
    { id: "gpt-4o", name: "GPT-4o", adapter: "OpenAi" },
    { id: "gpt-4o-mini", name: "GPT-4o Mini", adapter: "OpenAi" },
    { id: "gpt-4-turbo", name: "GPT-4 Turbo", adapter: "OpenAi" },
    { id: "gpt-4", name: "GPT-4", adapter: "OpenAi" },
    { id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", adapter: "OpenAi" },
    { id: "o3", name: "O3", adapter: "OpenAi" },
    { id: "o4-mini", name: "O4 Mini", adapter: "OpenAi" }
  ].freeze

  def self.find_model(id)
    MODELS.find { |m| m[:id] == id }
  end

  def self.adapter_for_model(model_id)
    model = find_model(model_id)
    return nil unless model
    "LLM::#{model[:adapter]}".constantize
  end

  attr_reader :api_key, :model, :user_id

  def initialize(api_key: nil, model: nil, user_id: nil)
    @api_key = api_key
    @model = model
    @user_id = user_id
  end

  def chat(messages, tools: [])
    raise NotImplementedError, "Subclasses must implement #chat"
  end

  def self.adapter_name
    name.demodulize.underscore.humanize
  end

  protected

  def format_tools_for_api
    raise NotImplementedError, "Subclasses must implement #format_tools_for_api"
  end

  def parse_tool_calls_from_response(response)
    raise NotImplementedError, "Subclasses must implement #parse_tool_calls_from_response"
  end
end
