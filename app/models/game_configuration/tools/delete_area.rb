module GameConfiguration
  module Tools
    class DeleteArea < Base
      def definition
        {
          "name" => "delete_area",
          "description" => "Delete an area from the game",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "area_id" => {
                "type" => "integer",
                "description" => "The ID of the area to delete"
              }
            },
            "required" => [ "area_id" ]
          }
        }
      end

      def execute(params)
        area = game.areas.find(params["area_id"])
        name = area.name
        area.destroy!

        {
          success: true,
          message: "Deleted area '#{name}'"
        }
      rescue ActiveRecord::RecordNotFound
        {
          success: false,
          error: "Area not found"
        }
      end
    end
  end
end
