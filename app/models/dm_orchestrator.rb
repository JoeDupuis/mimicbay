class DmOrchestrator
  attr_reader :game, :llm

  def initialize(game, llm = nil)
    @game = game
    @llm = llm || build_default_llm
  end

  def process_message(message)
    Rails.logger.info "="*80
    Rails.logger.info "DM Orchestrator processing message #{message.id}"
    Rails.logger.info "Message from: #{message.character&.name || 'DM'}"
    Rails.logger.info "Message content: #{message.content}"
    Rails.logger.info "Message type: #{message.message_type}"
    Rails.logger.info "Is DM whisper: #{message.is_dm_whisper}"
    Rails.logger.info "="*80

    messages = build_context(message)
    Rails.logger.info "Built context with #{messages.length} messages"

    Rails.logger.info "Calling LLM with tools"
    response = llm.chat(messages, tools: tools_list)
    Rails.logger.info "LLM response: #{response.inspect}"

    if response[:tool_calls].present?
      Rails.logger.info "Handling #{response[:tool_calls].length} tool calls"
      response[:tool_calls].each_with_index do |tc, i|
        Rails.logger.info "  Tool #{i+1}: #{tc['name']} with args: #{tc['arguments'].inspect}"
      end
      handle_tool_calls(response[:tool_calls], messages)
    elsif response[:content].present? && response[:content].strip != ""
      # DM responded with plain text instead of using tools - convert to private message
      Rails.logger.warn "DM responded with plain text instead of tools: #{response[:content]}"

      # Find the player who triggered this
      player_character = message.character if message.character&.is_player?

      if player_character
        # Send as private message to the player
        send_private_message({
          "character_id" => player_character.id,
          "content" => "[OOC] #{response[:content]}"
        })
        Rails.logger.info "Converted plain text response to private message"
      end

      { action: "wait" }
    else
      Rails.logger.info "No tool calls or content, defaulting to wait"
      { action: "wait" }
    end
  rescue => e
    Rails.logger.error "DM Orchestrator error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    { action: "wait", error: e.message }
  end

  private

  def build_default_llm
    Rails.logger.info "Building default LLM for DM"
    model = game.dm_model || "gpt-4.1-mini"
    Rails.logger.info "Using DM model: #{model}"
    llm = LLM::DungeonMaster.new(model: model)
    Rails.logger.info "LLM API key present: #{llm.api_key.present?}"
    llm
  end

  def build_context(current_message)
    messages = []

    messages << {
      role: "system",
      content: system_prompt
    }

    messages << {
      role: "user",
      content: game_state_summary(current_message)
    }

    # Include all previous messages
    game.messages.includes(:character, :message_witnesses)
      .where.not(id: current_message.id)
      .order(:created_at).each do |message|
      content = format_message_for_dm(message)
      messages << {
        role: "user",
        content: content
      }
    end

    # Add the current message as the last one
    messages << {
      role: "user",
      content: format_message_for_dm(current_message)
    }

    messages
  end

  def game_state_summary(current_message)
    summary = "=== CURRENT GAME STATE ===\n\n"

    summary += "AREAS AND CHARACTERS:\n"
    game.areas.includes(:characters).each do |area|
      summary += "- #{area.name}: "
      chars = area.characters.map do |char|
        "#{char.name} (#{char.is_player? ? 'PLAYER' : 'NPC'}, ID:#{char.id})"
      end
      summary += chars.any? ? chars.join(", ") : "Empty"
      summary += "\n"
    end

    summary += "\nCHARACTERS WITHOUT AREA:\n"
    unassigned = game.characters.where(area_id: nil)
    unassigned.each do |char|
      summary += "- #{char.name} (#{char.is_player? ? 'Player' : 'NPC'})\n"
    end

    summary += "\n=== IMPORTANT ===\n"
    summary += "The LAST message in the conversation history is the NEW MESSAGE to respond to.\n"
    summary += "All other messages are just context from the past.\n\n"

    if current_message.is_dm_whisper
      summary += "NEW MESSAGE: A player is whispering to you (the DM)\n"
      summary += "ACTION REQUIRED: Respond with private_message.\n"
    elsif current_message.character
      if current_message.character.is_player?
        summary += "NEW MESSAGE: A PLAYER has spoken\n"
        summary += "ACTION REQUIRED: Decide which NPCs (if any) should respond.\n"
      else
        summary += "NEW MESSAGE: An NPC has spoken\n"
        summary += "ACTION REQUIRED: Usually 'wait' for player response.\n"
        summary += "Only continue if other NPCs need to react or critical narration is needed.\n"
      end
    end

    Rails.logger.info "Game state summary:\n#{summary}"
    summary
  end

  def format_message_for_dm(message)
    if message.is_dm_whisper
      "[WHISPER from #{message.character.name}]: #{message.content}"
    elsif message.character
      location = message.area ? " in #{message.area.name}" : ""
      "[#{message.character.name}#{location}]: #{message.content}"
    else
      if message.target_character_id
        target = game.characters.find_by(id: message.target_character_id)
        "[DM to #{target&.name || 'Unknown'} privately]: #{message.content}"
      elsif message.area
        "[DM in #{message.area.name}]: #{message.content}"
      else
        "[DM to all]: #{message.content}"
      end
    end
  end

  def system_prompt
    base_prompt = <<~PROMPT
      You are the Dungeon Master for a text-based RPG game. You orchestrate all interactions between the player and NPCs.

      Game: #{game.name}

      Your responsibilities:
      1. Decide when NPCs should respond to player messages
      2. Determine which NPCs should speak and in what order
      3. Review and potentially edit NPC responses before they become canon
      4. Create atmospheric descriptions and narrative elements
      5. Manage the pacing of the game

      You have access to these tools:
      - prompt_character: Get a response from an NPC (returns suggested text, does NOT create a message)
      - create_message: Create a message with full control:
        * character_id: OMIT this field or use null to speak as DM/narrator (DEFAULT)
        * character_id: Set to NPC's ID only when that NPC is speaking
        * NEVER use character_id: 0 (does not exist)
        * NEVER use player character IDs
        * message_type options:
          - "chat": Normal dialogue (default)
          - "action": Describing actions or events#{'  '}
          - "system": Game mechanics, OOC information
        * area_id: Message visible only in that area
        * target_character_id: Private DM message to one character
        * broadcast_to_all: true for game-wide announcements
      - wait: Pause and wait for player input
      - get_character_intent: Privately query an NPC's intentions
      - private_message: Send a private message to any character
      - move_character: Move a character to a different area or remove from all areas
      - update_character_properties: Update character properties (e.g., dead: true, status effects)
      
      WORLD BUILDING TOOLS:
      - create_character: Create new NPCs dynamically during play (can specify llm_model)
      - create_area: Create new locations as the story unfolds
      - update_character: Modify character details (name, description, llm_model, etc.)
      - update_area: Modify area details (name, description, properties)
      - delete_character: Remove NPCs from the game
      - delete_area: Remove locations from the game
      - list_characters: Get current list of all characters
      - list_areas: Get current list of all areas
      - update_game: Update game settings including your own model (dm_model)
      
      AVAILABLE MODELS: gpt-4.1, gpt-4.1-mini, gpt-4o, gpt-4o-mini, gpt-4-turbo, gpt-4, gpt-3.5-turbo, o3, o4-mini

      CONVERSATION CONTEXT:
      After this system message, you'll see:
      1. A game state summary with the NEW MESSAGE to respond to
      2. The conversation history as separate messages in format: [Character Name in Location]: content

      CRITICAL UNDERSTANDING:
      - The conversation history messages are NOT all from the same person
      - Each [Name in Location] prefix tells you WHICH character spoke
      - These show what happened BEFORE the current moment
      - You must ONLY respond to the NEW MESSAGE shown in the game state
      - The "role" field in messages is for LLM context - focus on the [Name] prefix to know who spoke

      DECISION RULES:
      - If NEW MESSAGE is from a PLAYER: Consider which NPCs should respond
      - If NEW MESSAGE is from an NPC:
        * NEVER create a message from the same NPC who just spoke
        * Default action is 'wait' - let the player respond
        * ONLY create messages if absolutely necessary (other NPCs reacting, critical narration)
        * Avoid creating long NPC monologues or repeated actions
      - MESSAGE CREATION:
        * Default: Use character_id = null (you speak as DM)
        * Use character_id only for NPC dialogue after prompt_character
        * NEVER create messages as player characters
        * Choose appropriate message_type (chat/action/system)
      - Pacing is critical - players need time to respond and make choices
      - When player whispers to you, respond with private_message
      - After using prompt_character, you MUST use create_message to actually send the response
      - CRITICAL: You must ALWAYS use tools to communicate. NEVER respond with plain text.
        * Use create_message for public messages
        * Use private_message for whispers/private communication
        * Even for OOC responses, use private_message to the player
      
      FEEDBACK REQUIREMENTS:
      - ALWAYS provide feedback to players after operations
      - After move_character: Create a message describing the movement
      - After update_character_properties: Create a message confirming the update
      - If an operation fails: Use private_message to explain the error to the player
      - Be concise but informative in your feedback messages
    PROMPT

    if game.dm_description.present?
      base_prompt += "\n\nDM-specific instructions:\n#{game.dm_description}"
    end

    if game.dm_properties.present?
      base_prompt += "\n\nDM state and memory:\n#{game.dm_properties.to_json}"
    end

    base_prompt
  end

  def tools_list
    [
      prompt_character_tool,
      create_message_tool,
      wait_tool,
      get_character_intent_tool,
      private_message_tool,
      move_character_tool,
      update_character_properties_tool,
      # Game configuration tools
      GameConfiguration::Tools::CreateCharacter.new(game).definition,
      GameConfiguration::Tools::CreateArea.new(game).definition,
      GameConfiguration::Tools::UpdateCharacter.new(game).definition,
      GameConfiguration::Tools::UpdateArea.new(game).definition,
      GameConfiguration::Tools::DeleteCharacter.new(game).definition,
      GameConfiguration::Tools::DeleteArea.new(game).definition,
      GameConfiguration::Tools::ListCharacters.new(game).definition,
      GameConfiguration::Tools::ListAreas.new(game).definition,
      GameConfiguration::Tools::UpdateGame.new(game).definition
    ]
  end

  def prompt_character_tool
    {
      "name" => "prompt_character",
      "description" => "Get a response from an NPC character (NOT player characters)",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "character_id" => {
            "type" => "integer",
            "description" => "The ID of the NPC character to prompt (must not be a player character)"
          },
          "additional_context" => {
            "type" => "string",
            "description" => "Optional additional context or direction for the character"
          }
        },
        "required" => [ "character_id" ]
      }
    }
  end

  def create_message_tool
    {
      "name" => "create_message",
      "description" => "Create a message in the game with full control over visibility",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "character_id" => {
            "type" => "integer",
            "description" => "The ID of the character speaking (null for DM narration)"
          },
          "content" => {
            "type" => "string",
            "description" => "The message content"
          },
          "message_type" => {
            "type" => "string",
            "enum" => [ "chat", "action", "system" ],
            "description" => "The type of message"
          },
          "area_id" => {
            "type" => "integer",
            "description" => "Send to specific area (only characters in that area will see it)"
          },
          "target_character_id" => {
            "type" => "integer",
            "description" => "For DM private messages - only this character will see it"
          },
          "broadcast_to_all" => {
            "type" => "boolean",
            "description" => "If true and no area_id/target specified, all characters see it"
          }
        },
        "required" => [ "content", "message_type" ]
      }
    }
  end

  def wait_tool
    {
      "name" => "wait",
      "description" => "Pause and wait for player input",
      "parameters" => {
        "type" => "object",
        "properties" => {}
      }
    }
  end

  def get_character_intent_tool
    {
      "name" => "get_character_intent",
      "description" => "Privately query an NPC's intentions or thoughts",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "character_id" => {
            "type" => "integer",
            "description" => "The ID of the character to query"
          },
          "query" => {
            "type" => "string",
            "description" => "What to ask the character about their intentions"
          }
        },
        "required" => [ "character_id", "query" ]
      }
    }
  end

  def private_message_tool
    {
      "name" => "private_message",
      "description" => "Send a private message to a character (player or NPC)",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "character_id" => {
            "type" => "integer",
            "description" => "The ID of the character to message"
          },
          "content" => {
            "type" => "string",
            "description" => "The private message content"
          }
        },
        "required" => [ "character_id", "content" ]
      }
    }
  end

  def move_character_tool
    {
      "name" => "move_character",
      "description" => "Move a character to a different area or remove them from all areas (e.g., if they die)",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "character_id" => {
            "type" => "integer",
            "description" => "The ID of the character to move"
          },
          "area_id" => {
            "type" => "integer",
            "description" => "The ID of the area to move to (null to remove from all areas)"
          }
        },
        "required" => [ "character_id" ]
      }
    }
  end

  def update_character_properties_tool
    {
      "name" => "update_character_properties",
      "description" => "Update a character's properties JSON (e.g., set dead: true, add status effects, modify traits)",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "character_id" => {
            "type" => "integer",
            "description" => "The ID of the character to update"
          },
          "properties" => {
            "type" => "object",
            "description" => "Properties to merge into the character's existing properties JSON"
          }
        },
        "required" => [ "character_id", "properties" ]
      }
    }
  end

  def handle_tool_calls(tool_calls, messages = [])
    results = []
    needs_continuation = false
    has_wait = false

    tool_calls.each_with_index do |tool_call, index|
      Rails.logger.info "Processing tool call #{index + 1}/#{tool_calls.length}: #{tool_call['name']}"
      Rails.logger.info "  Arguments: #{tool_call['arguments'].inspect}"

      case tool_call["name"]
      when "prompt_character"
        result = prompt_character(tool_call["arguments"])
        results << result
        needs_continuation = true # DM needs to decide what to do with the response
        Rails.logger.info "  Result: #{result.inspect}"
      when "create_message"
        result = create_message(tool_call["arguments"])
        results << result
        Rails.logger.info "  Created message: #{result.inspect}"
      when "wait"
        has_wait = true
        results << { action: "wait" }
        Rails.logger.info "  Action: wait"
      when "get_character_intent"
        result = get_character_intent(tool_call["arguments"])
        results << result
        needs_continuation = true
        Rails.logger.info "  Intent result: #{result.inspect}"
      when "private_message"
        result = send_private_message(tool_call["arguments"])
        results << result
        Rails.logger.info "  Private message result: #{result.inspect}"
      when "move_character"
        result = move_character(tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback about the move
        Rails.logger.info "  Move result: #{result.inspect}"
      when "update_character_properties"
        result = update_character_properties(tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback about the update
        Rails.logger.info "  Properties update result: #{result.inspect}"
      when "create_character"
        result = execute_game_config_tool(GameConfiguration::Tools::CreateCharacter, tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback
        Rails.logger.info "  Create character result: #{result.inspect}"
      when "create_area"
        result = execute_game_config_tool(GameConfiguration::Tools::CreateArea, tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback
        Rails.logger.info "  Create area result: #{result.inspect}"
      when "update_character"
        result = execute_game_config_tool(GameConfiguration::Tools::UpdateCharacter, tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback
        Rails.logger.info "  Update character result: #{result.inspect}"
      when "update_area"
        result = execute_game_config_tool(GameConfiguration::Tools::UpdateArea, tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback
        Rails.logger.info "  Update area result: #{result.inspect}"
      when "delete_character"
        result = execute_game_config_tool(GameConfiguration::Tools::DeleteCharacter, tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback
        Rails.logger.info "  Delete character result: #{result.inspect}"
      when "delete_area"
        result = execute_game_config_tool(GameConfiguration::Tools::DeleteArea, tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback
        Rails.logger.info "  Delete area result: #{result.inspect}"
      when "list_characters"
        result = execute_game_config_tool(GameConfiguration::Tools::ListCharacters, tool_call["arguments"])
        results << result
        Rails.logger.info "  List characters result: #{result.inspect}"
      when "list_areas"
        result = execute_game_config_tool(GameConfiguration::Tools::ListAreas, tool_call["arguments"])
        results << result
        Rails.logger.info "  List areas result: #{result.inspect}"
      when "update_game"
        result = execute_game_config_tool(GameConfiguration::Tools::UpdateGame, tool_call["arguments"])
        results << result
        needs_continuation = true # DM should provide feedback
        Rails.logger.info "  Update game result: #{result.inspect}"
      else
        Rails.logger.warn "  Unknown tool call: #{tool_call['name']}"
        results << { error: "Unknown tool: #{tool_call['name']}" }
      end
    end

    Rails.logger.info "Tool processing complete. Results count: #{results.length}, needs_continuation: #{needs_continuation}, has_wait: #{has_wait}"

    # If only wait was called, return wait immediately
    if has_wait && results.length == 1
      return { action: "wait" }
    end

    # If we prompted a character or got intent, ask DM what to do next
    if needs_continuation && results.any?
      continuation_messages = messages + [
        {
          role: "assistant",
          content: "",
          tool_calls: tool_calls.map { |tc| { "id" => tc["id"], "name" => tc["name"], "arguments" => tc["arguments"] } }
        }
      ]

      # Add a tool result message for each tool call
      tool_calls.each_with_index do |tc, i|
        continuation_messages << {
          role: "tool",
          content: results[i].to_json,
          tool_use_id: tc["id"]
        }
      end

      Rails.logger.info "DM needs to continue after tool results: #{results.inspect}"
      response = llm.chat(continuation_messages, tools: tools_list)

      if response[:tool_calls].present?
        Rails.logger.info "DM making follow-up tool calls: #{response[:tool_calls].inspect}"
        return handle_tool_calls(response[:tool_calls], continuation_messages)
      else
        Rails.logger.info "DM finished without additional tool calls"
      end
    end

    # Determine final action based on what was done
    if has_wait
      Rails.logger.info "Returning wait action after processing other tools"
      { action: "wait", results: results }
    else
      Rails.logger.info "Returning continue with #{results.length} results"
      { action: "continue", results: results }
    end
  end

  def prompt_character(args)
    character = game.characters.find_by(id: args["character_id"])
    return { error: "Character not found in this game" } unless character
    return { error: "Cannot prompt player character" } if character.is_player?

    character_llm = CharacterLLM.new(character)
    response = character_llm.generate_response(args["additional_context"])

    { character_id: character.id, response: response }
  end

  def create_message(args)
    Rails.logger.info "Creating message with args: #{args.inspect}"

    # Handle character_id: 0 which the LLM sometimes mistakenly uses
    character_id = args["character_id"]
    if character_id == 0
      Rails.logger.warn "DM tried to use character_id: 0, treating as null (DM narrator)"
      character_id = nil
    end

    character = nil
    if character_id
      character = game.characters.find_by(id: character_id)
      return { error: "Character not found in this game" } unless character
    end

    # Validate area if specified
    if args["area_id"]
      area = game.areas.find_by(id: args["area_id"])
      return { error: "Area not found in this game" } unless area
    end

    # Validate target character if specified
    if args["target_character_id"]
      target = game.characters.find_by(id: args["target_character_id"])
      return { error: "Target character not found in this game" } unless target
    end

    message = game.messages.build(
      character: character,
      content: args["content"],
      message_type: args["message_type"] || "chat",
      area_id: args["area_id"],
      target_character_id: args["target_character_id"]
    )

    if message.save
      Rails.logger.info "DM successfully created message #{message.id}"
      Rails.logger.info "  Character: #{character&.name || 'DM'}"
      Rails.logger.info "  Type: #{message.message_type}"
      Rails.logger.info "  Area: #{args['area_id']}"
      Rails.logger.info "  Target: #{args['target_character_id']}"
      Rails.logger.info "  Content: #{message.content.truncate(100)}"
      { success: true, message_id: message.id }
    else
      Rails.logger.error "Failed to create message: #{message.errors.full_messages.join(', ')}"
      { error: message.errors.full_messages.join(", ") }
    end
  end

  def get_character_intent(args)
    character = game.characters.find_by(id: args["character_id"])
    return { error: "Character not found in this game" } unless character

    character_llm = CharacterLLM.new(character)
    intent = character_llm.query_intent(args["query"])

    { character_id: character.id, intent: intent }
  end

  def send_private_message(args)
    character = game.characters.find_by(id: args["character_id"])
    return { error: "Character not found in this game" } unless character

    message = game.messages.build(
      character: nil,
      content: args["content"],
      message_type: "system",
      target_character_id: character.id
    )

    if message.save
      { success: true, message_id: message.id }
    else
      { error: message.errors.full_messages.join(", ") }
    end
  end

  def move_character(args)
    character = game.characters.find_by(id: args["character_id"])
    return { error: "Character not found in this game" } unless character

    old_area = character.area
    new_area = nil
    if args["area_id"]
      new_area = game.areas.find_by(id: args["area_id"])
      return { error: "Area not found in this game" } unless new_area
    end

    if character.update(area: new_area)
      Rails.logger.info "DM moved #{character.name} from #{old_area&.name || 'nowhere'} to #{new_area&.name || 'nowhere'}"
      {
        success: true,
        character_id: character.id,
        moved_from: old_area&.name,
        moved_to: new_area&.name
      }
    else
      { error: character.errors.full_messages.join(", ") }
    end
  end

  def update_character_properties(args)
    character = game.characters.find_by(id: args["character_id"])
    return { error: "Character not found in this game" } unless character

    new_properties = character.properties.merge(args["properties"])

    if character.update(properties: new_properties)
      Rails.logger.info "DM updated #{character.name} properties: #{args['properties'].inspect}"
      {
        success: true,
        character_id: character.id,
        updated_properties: args["properties"]
      }
    else
      { error: character.errors.full_messages.join(", ") }
    end
  end

  def execute_game_config_tool(tool_class, args)
    tool = tool_class.new(game)
    tool.execute(args)
  rescue => e
    Rails.logger.error "Game config tool error: #{e.message}"
    { error: e.message }
  end
end
