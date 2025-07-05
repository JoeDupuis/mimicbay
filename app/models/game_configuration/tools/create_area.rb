module GameConfiguration
  module Tools
    class CreateArea < Base
      def definition
        {
          "name" => "create_area",
          "description" => "Create a new area in the game",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "name" => {
                "type" => "string",
                "description" => "The name of the area"
              },
              "description" => {
                "type" => "string",
                "description" => "A detailed description of the area"
              },
              "properties" => {
                "type" => "object",
                "description" => "Additional properties for the area (optional)",
                "additionalProperties" => true
              }
            },
            "required" => [ "name", "description" ]
          }
        }
      end

      def execute(params)
        area = game.areas.create!(
          name: params["name"],
          description: params["description"],
          properties: params["properties"] || {}
        )

        {
          success: true,
          area_id: area.id,
          name: area.name,
          message: "Created area '#{area.name}'"
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
