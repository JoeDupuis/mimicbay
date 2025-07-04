class AddIsDmWhisperToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :is_dm_whisper, :boolean, default: false, null: false
  end
end
