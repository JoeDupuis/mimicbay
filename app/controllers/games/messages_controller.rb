class Games::MessagesController < ApplicationController
  before_action :set_game
  before_action :set_player_character

  def create
    @message = @game.messages.build(message_params)
    @message.character = @player_character
    @message.area = @player_character.area
    @message.message_type = "chat"

    if @message.save
      create_witnesses_for_message(@message)
      broadcast_message(@message)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "games/messages/message", locals: { message: @message }) }
        format.html { redirect_to game_play_path(@game) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_message_form", partial: "games/messages/form", locals: { game: @game, message: @message }) }
        format.html { redirect_to game_play_path(@game), alert: @message.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def set_player_character
    @player_character = @game.characters.player.first
    redirect_to game_play_path(@game), alert: "No player character found" unless @player_character
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def create_witnesses_for_message(message)
    if message.area.present?
      # Area-based message: all characters in area can see it
      characters_in_area = @game.characters.where(area: message.area)
      characters_in_area.each do |character|
        message.message_witnesses.create(character: character)
      end
    else
      # Private message: only sender can see it
      # The game owner (acting as DM) can see all messages through the DM interface
      message.message_witnesses.create(character: message.character) if message.character
    end
  end

  def broadcast_message(message)
    message.witnesses.each do |character|
      Turbo::StreamsChannel.broadcast_append_to(
        "game_#{@game.id}_character_#{character.id}_messages",
        target: "messages",
        partial: "games/messages/message",
        locals: { message: message }
      )
    end
  end
end
