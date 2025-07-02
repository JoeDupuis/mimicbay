class AddAreaToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_reference :characters, :area, null: true, foreign_key: true
  end
end
