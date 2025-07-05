require "test_helper"

class GameConfiguration::Tools::ListAreasTest < ActiveSupport::TestCase
  setup do
    @game = games(:game_without_characters)
    @tool = GameConfiguration::Tools::ListAreas.new(@game)
  end

  test "definition returns proper structure" do
    definition = @tool.definition

    assert_equal "list_areas", definition["name"]
    assert_equal "List all areas in the game", definition["description"]
    assert_equal "object", definition["parameters"]["type"]
    assert_equal({}, definition["parameters"]["properties"])
    assert_equal [], definition["parameters"]["required"]
  end

  test "execute returns all areas in the game" do
    # Create some areas
    area1 = @game.areas.create!(name: "Forest", description: "A green forest")
    area2 = @game.areas.create!(name: "Castle", description: "A grand castle")

    result = @tool.execute({})

    assert result[:success]
    assert_equal 2, result[:count]
    assert_equal 2, result[:areas].length

    area_names = result[:areas].map { |a| a[:name] }
    assert_includes area_names, "Forest"
    assert_includes area_names, "Castle"

    forest_area = result[:areas].find { |a| a[:name] == "Forest" }
    assert_equal area1.id, forest_area[:id]
    assert_equal "A green forest", forest_area[:description]
  end

  test "execute returns empty array when no areas exist" do
    result = @tool.execute({})

    assert result[:success]
    assert_equal 0, result[:count]
    assert_equal [], result[:areas]
  end

  test "execute includes character count for each area" do
    area = @game.areas.create!(name: "Town", description: "A busy town")
    area.characters.create!(name: "Villager 1", description: "A villager", game: @game)
    area.characters.create!(name: "Villager 2", description: "Another villager", game: @game)

    result = @tool.execute({})

    town_area = result[:areas].find { |a| a[:name] == "Town" }
    assert_equal 2, town_area[:character_count]
  end
end
