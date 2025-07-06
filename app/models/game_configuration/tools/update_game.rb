module GameConfiguration
  module Tools
    class UpdateGame < Base
      def definition
        {
          "name" => "update_game",
          "description" => "Update game settings including DM model and instructions",
          "parameters" => {
            "type" => "object",
            "properties" => {
              "dm_model" => {
                "type" => "string",
                "description" => "The LLM model for the DM to use (e.g., 'gpt-4.1', 'o3', 'o4-mini')",
                "enum" => LLM::MODELS.map { |m| m[:id] }
              },
              "dm_description" => {
                "type" => "string",
                "description" => "Instructions or context for the DM"
              },
              "dm_properties" => {
                "type" => "object",
                "description" => "Additional properties for the DM to track",
                "additionalProperties" => true
              }
            },
            "required" => []
          }
        }
      end

      def execute(params)
        update_params = {}
        update_params[:dm_model] = params["dm_model"] if params["dm_model"].present?
        update_params[:dm_description] = params["dm_description"] if params.key?("dm_description")
        
        if params["dm_properties"].present?
          # Merge new properties with existing ones
          update_params[:dm_properties] = game.dm_properties.merge(params["dm_properties"])
        end

        if game.update(update_params)
          {
            success: true,
            message: "Game settings updated",
            dm_model: game.dm_model,
            dm_description: game.dm_description,
            dm_properties: game.dm_properties
          }
        else
          {
            success: false,
            error: game.errors.full_messages.join(", ")
          }
        end
      end
    end
  end
end