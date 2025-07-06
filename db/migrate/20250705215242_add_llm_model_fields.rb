class AddLLMModelFields < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :dm_model, :string, default: "gpt-4.1-mini"
    add_column :characters, :llm_model, :string, default: "gpt-4.1-mini"
  end
end