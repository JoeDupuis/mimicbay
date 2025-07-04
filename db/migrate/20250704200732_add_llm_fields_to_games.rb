class AddLlmFieldsToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :llm_adapter, :string
    add_column :games, :llm_model, :string
  end
end
