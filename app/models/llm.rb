module LLM
  MODELS = [
    { id: "gpt-4o", name: "GPT-4o", adapter: "OpenAi" },
    { id: "gpt-4o-mini", name: "GPT-4o Mini", adapter: "OpenAi" },
    { id: "gpt-4-turbo", name: "GPT-4 Turbo", adapter: "OpenAi" },
    { id: "gpt-4", name: "GPT-4", adapter: "OpenAi" },
    { id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", adapter: "OpenAi" }
  ].freeze

  def self.find_model(id)
    MODELS.find { |m| m[:id] == id }
  end

  def self.adapter_for_model(model_id)
    model = find_model(model_id)
    return nil unless model
    "LLM::#{model[:adapter]}".constantize
  end

  class Base
    attr_reader :api_key, :model, :user_id

    def initialize(api_key: nil, model: nil, user_id: nil)
      @api_key = api_key
      @model = model || default_model
      @user_id = user_id
    end

    def chat(messages, tools: [])
      raise NotImplementedError, "Subclasses must implement #chat"
    end

    def available_models
      raise NotImplementedError, "Subclasses must implement #available_models"
    end

    def default_model
      available_models.first
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
end
