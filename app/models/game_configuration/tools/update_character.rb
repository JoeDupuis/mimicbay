module GameConfiguration
  module Tools
    class UpdateCharacter < Base
      def definition
        {
          "name" => "update_character",
          "description" => "Update an existing character in the game",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "character_id" => {
                "type" => "integer",
                "description" => "The ID of the character to update"
              },
              "name" => {
                "type" => "string",
                "description" => "The new name of the character (optional)"
              },
              "description" => {
                "type" => "string",
                "description" => "The new description of the character (optional)"
              },
              "area_id" => {
                "type" => "integer",
                "description" => "The ID of the area to move the character to (optional)"
              },
              "is_player" => {
                "type" => "boolean",
                "description" => "Whether this is the player character (optional)"
              },
              "properties" => {
                "type" => "object",
                "description" => "Additional properties to update (optional)",
                "additionalProperties" => true
              },
              "llm_model" => {
                "type" => "string",
                "description" => "The LLM model for the character to use (e.g., 'gpt-4.1', 'o3', 'o4-mini')",
                "enum" => LLM::MODELS.map { |m| m[:id] }
              }
            },
            "required" => [ "character_id" ]
          }
        }
      end

      def execute(params)
        character = game.characters.find(params["character_id"])

        update_params = {}
        update_params[:name] = params["name"] if params.key?("name")
        update_params[:description] = params["description"] if params.key?("description")
        update_params[:is_player] = params["is_player"] if params.key?("is_player")
        update_params[:properties] = character.properties.merge(params["properties"]) if params.key?("properties")
        update_params[:llm_model] = params["llm_model"] if params.key?("llm_model")

        if params.key?("area_id")
          if params["area_id"]
            area = game.areas.find(params["area_id"])
            update_params[:area] = area
          else
            update_params[:area] = nil
          end
        end

        character.update!(update_params)

        {
          success: true,
          character_id: character.id,
          name: character.name,
          message: "Updated character '#{character.name}'"
        }
      rescue ActiveRecord::RecordNotFound
        {
          success: false,
          error: "Character or area not found"
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
