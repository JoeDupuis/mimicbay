module GameConfiguration
  module Tools
    class DeleteCharacter < Base
      def definition
        {
          "name" => "delete_character",
          "description" => "Delete a character from the game",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "character_id" => {
                "type" => "integer",
                "description" => "The ID of the character to delete"
              }
            },
            "required" => [ "character_id" ]
          }
        }
      end

      def execute(params)
        character = game.characters.find(params["character_id"])

        if character.is_player?
          return {
            success: false,
            error: "Cannot delete the player character"
          }
        end

        name = character.name
        character.destroy!

        {
          success: true,
          message: "Deleted character '#{name}'"
        }
      rescue ActiveRecord::RecordNotFound
        {
          success: false,
          error: "Character not found"
        }
      end
    end
  end
end
