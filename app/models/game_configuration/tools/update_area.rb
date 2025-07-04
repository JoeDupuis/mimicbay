module GameConfiguration
  module Tools
    class UpdateArea < Base
      def definition
        {
          name: "update_area",
          description: "Update an existing area in the game",
          parameters: {
            type: "object",
            properties: {
              area_id: {
                type: "integer",
                description: "The ID of the area to update"
              },
              name: {
                type: "string",
                description: "The new name of the area (optional)"
              },
              description: {
                type: "string",
                description: "The new description of the area (optional)"
              },
              properties: {
                type: "object",
                description: "Additional properties to update (optional)",
                additionalProperties: true
              }
            },
            required: [ "area_id" ]
          }
        }
      end

      def execute(params)
        area = game.areas.find(params["area_id"])

        update_params = {}
        update_params[:name] = params["name"] if params.key?("name")
        update_params[:description] = params["description"] if params.key?("description")
        update_params[:properties] = area.properties.merge(params["properties"]) if params.key?("properties")

        area.update!(update_params)

        {
          success: true,
          area_id: area.id,
          name: area.name,
          message: "Updated area '#{area.name}'"
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
