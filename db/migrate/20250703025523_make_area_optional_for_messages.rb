class MakeAreaOptionalForMessages < ActiveRecord::Migration[8.1]
  def change
    change_column_null :messages, :area_id, true
  end
end
