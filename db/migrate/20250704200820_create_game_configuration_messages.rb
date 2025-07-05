class CreateGameConfigurationMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :game_configuration_messages do |t|
      t.references :game_configuration_session, null: false, foreign_key: true
      t.string :role
      t.text :content
      t.string :model
      t.json :tool_calls
      t.json :tool_results

      t.timestamps
    end
  end
end
