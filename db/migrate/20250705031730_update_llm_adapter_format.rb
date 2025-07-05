class UpdateLLMAdapterFormat < ActiveRecord::Migration[8.1]
  def up
    Game.where(llm_adapter: "LLM::OpenAi").update_all(llm_adapter: "OpenAi")
  end

  def down
    Game.where(llm_adapter: "OpenAi").update_all(llm_adapter: "LLM::OpenAi")
  end
end
