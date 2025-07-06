module GameConfiguration
  module Tools
    class CreateCharacter < Base
      def definition
        {
          "name" => "create_character",
          "description" => "Create a new character (NPC) in the game",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "name" => {
                "type" => "string",
                "description" => "The name of the character"
              },
              "description" => {
                "type" => "string",
                "description" => "A detailed description of the character"
              },
              "area_id" => {
                "type" => "integer",
                "description" => "The ID of the area where the character is located (optional)"
              },
              "is_player" => {
                "type" => "boolean",
                "description" => "Whether this is the player character (optional, defaults to false)"
              },
              "properties" => {
                "type" => "object",
                "description" => "Additional properties for the character (optional)",
                "additionalProperties" => true
              },
              "llm_model" => {
                "type" => "string",
                "description" => "The LLM model for the character to use (e.g., 'gpt-4.1', 'o3', 'o4-mini')",
                "enum" => LLM::MODELS.map { |m| m[:id] }
              }
            },
            "required" => [ "name", "description" ]
          }
        }
      end

      def execute(params)
        character_params = {
          name: params["name"],
          description: params["description"],
          properties: params["properties"] || {},
          is_player: params["is_player"] || false
        }
        
        character_params[:llm_model] = params["llm_model"] if params["llm_model"].present?

        if params["area_id"]
          area = game.areas.find(params["area_id"])
          character_params[:area] = area
        end

        character = game.characters.create!(character_params)

        {
          success: true,
          character_id: character.id,
          name: character.name,
          message: "Created character '#{character.name}'"
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
