class LLM::Character < LLM::OpenAi
  def initialize(model: "gpt-4.1-mini", api_key: nil, user_id: nil)
    super(api_key: api_key, model: model, user_id: user_id)
  end
end