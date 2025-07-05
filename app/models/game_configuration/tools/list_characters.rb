module GameConfiguration
  module Tools
    class ListCharacters < Base
      def definition
        {
          "name" => "list_characters",
          "description" => "List all characters in the game",
          "parameters" => {
            "type" => "object",
            "properties" => {},
            "required" => []
          }
        }
      end

      def execute(_params)
        characters = game.characters.map do |character|
          {
            id: character.id,
            name: character.name,
            description: character.description,
            is_player: character.is_player,
            area_id: character.area_id,
            area_name: character.area&.name,
            properties: character.properties
          }
        end

        {
          success: true,
          characters: characters,
          count: characters.count,
          player_count: characters.count { |c| c[:is_player] },
          npc_count: characters.count { |c| !c[:is_player] }
        }
      end
    end
  end
end
