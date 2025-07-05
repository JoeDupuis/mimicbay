class Games::Configurations::ModelsController < ApplicationController
  def index
    adapter_name = params[:adapter]
    return render json: { models: [], default: nil } unless adapter_name.present?

    # Whitelist of allowed adapters to prevent arbitrary code execution
    allowed_adapters = [ "OpenAi" ]
    unless allowed_adapters.include?(adapter_name)
      return render json: { models: [], default: nil }
    end

    begin
      adapter_class = "LLM::#{adapter_name}".constantize
      adapter = adapter_class.new

      render json: {
        models: adapter.available_models,
        default: adapter.default_model
      }
    rescue NameError
      render json: { models: [], default: nil }
    end
  end
end
