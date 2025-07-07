class CharacterLLM
  attr_reader :character, :llm

  def initialize(character, llm = nil)
    @character = character
    @llm = llm || build_default_llm
  end

  def generate_response(additional_context = nil)
    messages = build_conversation_context(additional_context)
    response = llm.chat(messages)
    response[:content]
  end

  def query_intent(query)
    messages = build_conversation_context

    messages << {
      role: "user",
      content: "[DM Query]: #{query}"
    }

    response = llm.chat(messages)
    response[:content]
  end

  private

  def build_default_llm
    model = character.llm_model || "gpt-4.1-mini"
    LLM::OpenAi.new(model: model)
  end

  def build_conversation_context(additional_context = nil)
    messages = []

    messages << {
      role: "system",
      content: system_prompt(additional_context)
    }

    witnessed_messages = character.witnessed_messages
      .includes(:character)
      .order(:created_at)

    witnessed_messages.each do |message|
      if message.character == character
        messages << {
          role: "assistant",
          content: message.content
        }
      else
        speaker_name = message.character ? message.character.name : "DM"
        messages << {
          role: "user",
          content: "[#{speaker_name}]: #{message.content}"
        }
      end
    end

    messages
  end

  def system_prompt(additional_context = nil)
    base_prompt = <<~PROMPT
      You are playing the character #{character.name} in a text-based RPG game.

      Character details:
      - Name: #{character.name}
      - Current location: #{character.area&.name || "Unknown"}
      #{character_properties_prompt}

      Game rules:
      1. Stay in character at all times
      2. Your responses will be reviewed by the DM before becoming part of the game
      3. You can ask the DM questions or request actions by prefixing with [OOC:]#{' '}
      4. Respond naturally to the situation and other characters
      5. Be concise - aim for 1-3 sentences unless the situation demands more
      6. Don't control other characters or narrate outcomes beyond your actions

      You are participating in the game: #{character.game.name}
    PROMPT

    if additional_context
      base_prompt += "\n\nAdditional context from DM: #{additional_context}"
    end

    base_prompt
  end

  def character_properties_prompt
    return "" unless character.properties.present?

    prompt_parts = []

    if character.properties["personality"]
      prompt_parts << "- Personality: #{character.properties['personality']}"
    end

    if character.properties["background"]
      prompt_parts << "- Background: #{character.properties['background']}"
    end

    if character.properties["goals"]
      prompt_parts << "- Goals: #{character.properties['goals']}"
    end

    if character.properties["knowledge"]
      prompt_parts << "- Knowledge: #{character.properties['knowledge']}"
    end

    if character.properties["traits"]
      prompt_parts << "- Traits: #{character.properties['traits']}"
    end

    other_properties = character.properties.except("personality", "background", "goals", "knowledge", "traits")
    if other_properties.present?
      prompt_parts << "- Additional properties: #{other_properties.to_json}"
    end

    prompt_parts.join("\n")
  end
end
