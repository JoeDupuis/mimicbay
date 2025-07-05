module GameConfiguration
  module Tools
    class SetPlayerCharacter < Base
      def definition
        {
          "name" => "set_player_character",
          "description" => "Create or update the player character for the game",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "name" => {
                "type" => "string",
                "description" => "The name of the player character"
              },
              "description" => {
                "type" => "string",
                "description" => "A detailed description of the player character"
              },
              "area_id" => {
                "type" => "integer",
                "description" => "The ID of the starting area for the player (optional)"
              },
              "properties" => {
                "type" => "object",
                "description" => "Additional properties for the player character (optional)",
                "additionalProperties" => true
              }
            },
            "required" => [ "name", "description" ]
          }
        }
      end

      def execute(params)
        player_character = game.characters.player.first

        character_params = {
          name: params["name"],
          description: params["description"],
          properties: params["properties"] || {},
          is_player: true
        }

        if params["area_id"]
          area = game.areas.find(params["area_id"])
          character_params[:area] = area
        end

        if player_character
          player_character.update!(character_params)
          message = "Updated player character '#{player_character.name}'"
        else
          player_character = game.characters.create!(character_params)
          message = "Created player character '#{player_character.name}'"
        end

        {
          success: true,
          character_id: player_character.id,
          name: player_character.name,
          message: message
        }
      rescue ActiveRecord::RecordNotFound
        {
          success: false,
          error: "Area not found"
        }
      rescue ActiveRecord::RecordInvalid => e
        {
          success: false,
          error: e.message
        }
      end
    end
  end
end
