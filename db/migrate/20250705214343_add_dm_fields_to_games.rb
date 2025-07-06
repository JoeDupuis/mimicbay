class AddDmFieldsToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :dm_description, :text
    add_column :games, :dm_properties, :json
  end
end
