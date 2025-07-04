module LLM
  class Base
    attr_reader :api_key, :model

    def initialize(api_key:, model: nil)
      @api_key = api_key
      @model = model || default_model
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

    def self.descendants_names
      descendants.map(&:name).sort
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
