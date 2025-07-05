module GameConfiguration
  module Tools
    class Base
      attr_reader :game

      TOOL_CLASSES = [
        CreateArea,
        CreateCharacter,
        DeleteArea,
        DeleteCharacter,
        ListAreas,
        ListCharacters,
        SetPlayerCharacter,
        UpdateArea,
        UpdateCharacter
      ].freeze

      def initialize(game)
        @game = game
      end

      def execute(params)
        raise NotImplementedError, "Subclasses must implement #execute"
      end

      def definition
        raise NotImplementedError, "Subclasses must implement #definition"
      end

      def self.all_definitions
        TOOL_CLASSES.map do |tool_class|
          tool_class.new(nil).definition
        end
      end

      def self.find_by_name(name)
        TOOL_CLASSES.find { |tool| tool.new(nil).definition[:name] == name }
      end
    end
  end
end
