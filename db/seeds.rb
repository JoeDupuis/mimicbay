# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  user = User.find_or_create_by!(email_address: "dev@example.com") do |u|
    u.password = "password"
    u.role = :admin
  end

  # Create sample games
  game1 = Game.find_or_create_by!(name: "The Lost Kingdom", user: user)
  game2 = Game.find_or_create_by!(name: "Space Adventures", user: user)

  # Create areas for game1
  castle_entrance = Area.find_or_create_by!(name: "Castle Entrance", game: game1) do |area|
    area.description = "A massive stone archway marks the entrance to the ancient castle"
    area.properties = { "difficulty": "easy", "treasure": [ "rusty key", "old map" ] }
  end

  Area.find_or_create_by!(name: "Dark Forest", game: game1) do |area|
    area.description = "Twisted trees block out most of the sunlight in this eerie forest"
    area.properties = { "difficulty": "medium", "enemies": [ "wolves", "bandits" ] }
  end

  Area.find_or_create_by!(name: "Dragon's Lair", game: game1) do |area|
    area.description = "The air is thick with smoke and the smell of sulfur"
    area.properties = { "difficulty": "hard", "boss": "Ancient Red Dragon" }
  end

  # Create characters for game1
  sir_galahad = Character.find_or_create_by!(name: "Sir Galahad", game: game1) do |char|
    char.description = "A noble knight in shining armor"
    char.properties = { "class": "Knight", "level": 10, "stats": { "strength": 18, "wisdom": 12 } }
    char.is_player = true
    char.area = castle_entrance
  end
  sir_galahad.update!(is_player: true, area: castle_entrance)

  elara = Character.find_or_create_by!(name: "Elara the Wise", game: game1) do |char|
    char.description = "An ancient elf wizard with centuries of knowledge"
    char.properties = { "class": "Wizard", "level": 15, "spells": [ "fireball", "teleport" ] }
    char.is_player = false
    char.area = castle_entrance
  end
  elara.update!(is_player: false, area: castle_entrance)

  # Create areas for game2
  Area.find_or_create_by!(name: "Space Station Alpha", game: game2) do |area|
    area.description = "The central hub of human activity in this sector"
    area.properties = { "services": [ "repair", "refuel", "trade" ], "faction": "Federation" }
  end

  Area.find_or_create_by!(name: "Asteroid Field", game: game2) do |area|
    area.description = "A dangerous field of floating rock and debris"
    area.properties = { "hazards": [ "asteroids", "pirates" ], "resources": [ "ore", "crystals" ] }
  end

  # Create characters for game2
  Character.find_or_create_by!(name: "Captain Rex", game: game2) do |char|
    char.description = "A grizzled space captain with years of experience"
    char.properties = { "ship": "Stellar Phoenix", "reputation": 85, "skills": [ "piloting", "negotiation" ] }
  end

  Character.find_or_create_by!(name: "ARIA-7", game: game2) do |char|
    char.description = "An advanced AI companion"
    char.properties = { "type": "AI", "version": "7.3.2", "capabilities": [ "hacking", "analysis", "translation" ] }
  end

  game1.update! state: :playing
end
