class AddModelToGameConfigurationMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :game_configuration_messages, :model, :string
  end
end
