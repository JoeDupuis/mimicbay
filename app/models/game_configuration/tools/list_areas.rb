module GameConfiguration
  module Tools
    class ListAreas < Base
      def definition
        {
          "name" => "list_areas",
          "description" => "List all areas in the game",
          "parameters" => {
            "type" => "object",
            "properties" => {},
            "required" => []
          }
        }
      end

      def execute(_params)
        areas = game.areas.map do |area|
          {
            id: area.id,
            name: area.name,
            description: area.description,
            properties: area.properties,
            character_count: area.characters.count
          }
        end

        {
          success: true,
          areas: areas,
          count: areas.count
        }
      end
    end
  end
end
