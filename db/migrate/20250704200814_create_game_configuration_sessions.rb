class CreateGameConfigurationSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_configuration_sessions do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
