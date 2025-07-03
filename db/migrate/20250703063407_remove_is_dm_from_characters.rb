class RemoveIsDmFromCharacters < ActiveRecord::Migration[8.1]
  def change
    remove_index :characters, [:game_id, :is_dm]
    remove_column :characters, :is_dm, :boolean
  end
end