class AddLanguageModelFieldsToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :llm_adapter, :string
  end
end
