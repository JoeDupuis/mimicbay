require "test_helper"

class GameConfiguration::Tools::CreateCharacterTest < ActiveSupport::TestCase
  setup do
    @game = games(:game_without_characters)
    @area = @game.areas.create!(name: "Town Square", description: "The center of town")
    @tool = GameConfiguration::Tools::CreateCharacter.new(@game)
  end

  test "definition returns proper structure" do
    definition = @tool.definition
    
    assert_equal "create_character", definition["name"]
    assert_equal "Create a new character (NPC) in the game", definition["description"]
    assert_equal "object", definition["parameters"]["type"]
    assert definition["parameters"]["properties"]["name"].present?
    assert definition["parameters"]["properties"]["description"].present?
    assert definition["parameters"]["properties"]["area_id"].present?
    assert definition["parameters"]["properties"]["is_player"].present?
    assert definition["parameters"]["properties"]["properties"].present?
    assert_equal ["name", "description"], definition["parameters"]["required"]
  end

  test "execute creates NPC character with valid params" do
    params = {
      "name" => "Gandalf",
      "description" => "A wise wizard",
      "area_id" => @area.id,
      "properties" => { "class" => "wizard", "level" => 20 }
    }
    
    assert_difference -> { @game.characters.count }, 1 do
      result = @tool.execute(params)
      
      assert result[:success]
      assert result[:character_id].present?
      assert_equal "Gandalf", result[:name]
      assert_equal "Created character 'Gandalf'", result[:message]
    end
    
    character = @game.characters.last
    assert_equal "Gandalf", character.name
    assert_equal "A wise wizard", character.description
    assert_equal @area, character.area
    assert_not character.is_player?
    assert_equal({ "class" => "wizard", "level" => 20 }, character.properties)
  end

  test "execute creates player character when is_player is true" do
    params = {
      "name" => "Hero",
      "description" => "The main protagonist",
      "is_player" => true,
      "area_id" => @area.id
    }
    
    assert_difference -> { @game.characters.count }, 1 do
      result = @tool.execute(params)
      
      assert result[:success]
      assert_equal "Hero", result[:name]
    end
    
    character = @game.characters.last
    assert character.is_player?
  end

  test "execute creates character without optional params" do
    params = {
      "name" => "Simple NPC",
      "description" => "A basic character"
    }
    
    assert_difference -> { @game.characters.count }, 1 do
      result = @tool.execute(params)
      
      assert result[:success]
      assert_equal "Simple NPC", result[:name]
    end
    
    character = @game.characters.last
    assert_nil character.area
    assert_not character.is_player?
    assert_equal({}, character.properties)
  end

  test "execute returns error for invalid area_id" do
    params = {
      "name" => "Character",
      "description" => "A character",
      "area_id" => 99999 # Non-existent area
    }
    
    assert_no_difference -> { @game.characters.count } do
      result = @tool.execute(params)
      
      assert_not result[:success]
      assert_equal "Area not found", result[:error]
    end
  end

  test "execute returns error for invalid params" do
    params = {
      "name" => "", # Empty name should fail validation
      "description" => "A description"
    }
    
    assert_no_difference -> { @game.characters.count } do
      result = @tool.execute(params)
      
      assert_not result[:success]
      assert result[:error].present?
    end
  end
end