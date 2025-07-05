require "test_helper"

class GameConfiguration::Tools::BaseTest < ActiveSupport::TestCase
  setup do
    @game = games(:game_without_characters)
  end

  test "all_definitions returns array of tool definitions" do
    definitions = GameConfiguration::Tools::Base.all_definitions
    
    assert_kind_of Array, definitions
    assert_equal GameConfiguration::Tools::Base.tool_classes.length, definitions.length
    
    definitions.each do |definition|
      assert definition["name"].present?
      assert definition["description"].present?
      assert definition["parameters"].present?
      assert_equal "object", definition["parameters"]["type"]
    end
  end

  test "find_by_name returns correct tool class" do
    tool_class = GameConfiguration::Tools::Base.find_by_name("create_area")
    assert_equal GameConfiguration::Tools::CreateArea, tool_class
    
    tool_class = GameConfiguration::Tools::Base.find_by_name("create_character")
    assert_equal GameConfiguration::Tools::CreateCharacter, tool_class
    
    tool_class = GameConfiguration::Tools::Base.find_by_name("list_areas")
    assert_equal GameConfiguration::Tools::ListAreas, tool_class
  end

  test "find_by_name returns nil for unknown tool" do
    assert_nil GameConfiguration::Tools::Base.find_by_name("unknown_tool")
    assert_nil GameConfiguration::Tools::Base.find_by_name("")
    assert_nil GameConfiguration::Tools::Base.find_by_name(nil)
  end

  test "base class raises NotImplementedError for execute" do
    base_tool = GameConfiguration::Tools::Base.new(@game)
    
    assert_raises(NotImplementedError) do
      base_tool.execute({})
    end
  end

  test "base class raises NotImplementedError for definition" do
    base_tool = GameConfiguration::Tools::Base.new(@game)
    
    assert_raises(NotImplementedError) do
      base_tool.definition
    end
  end

  test "tool_classes includes all expected tool classes" do
    expected_classes = [
      GameConfiguration::Tools::CreateArea,
      GameConfiguration::Tools::CreateCharacter,
      GameConfiguration::Tools::DeleteArea,
      GameConfiguration::Tools::DeleteCharacter,
      GameConfiguration::Tools::ListAreas,
      GameConfiguration::Tools::ListCharacters,
      GameConfiguration::Tools::UpdateArea,
      GameConfiguration::Tools::UpdateCharacter
    ]
    
    assert_equal expected_classes.sort_by(&:name), 
                 GameConfiguration::Tools::Base.tool_classes.sort_by(&:name)
  end
end