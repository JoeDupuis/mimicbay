class RemoveLLMAdapterFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_column :games, :llm_adapter, :string
  end
end
