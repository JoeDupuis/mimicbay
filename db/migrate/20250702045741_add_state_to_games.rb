class AddStateToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :state, :integer, default: 0, null: false
  end
end
