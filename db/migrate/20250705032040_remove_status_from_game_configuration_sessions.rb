class RemoveStatusFromGameConfigurationSessions < ActiveRecord::Migration[8.1]
  def change
    remove_column :game_configuration_sessions, :status, :integer
  end
end
