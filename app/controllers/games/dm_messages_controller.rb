class Games::DmMessagesController < ApplicationController
  before_action :set_game
  before_action :set_dm_character

  def create
    @message = @game.messages.build(dm_message_params)
    @message.character = @dm_character
    @message.message_type = params[:message][:message_type] || "system"

    if @message.save
      create_witnesses_for_dm_message(@message)
      broadcast_message(@message)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "games/messages/message", locals: { message: @message }) }
        format.html { redirect_to game_dm_path(@game) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_dm_message_form", partial: "games/dm_messages/form", locals: { game: @game, message: @message }) }
        format.html { redirect_to game_dm_path(@game), alert: @message.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def set_dm_character
    @dm_character = @game.characters.dm.first
    redirect_to @game, alert: "No DM character found" unless @dm_character
  end

  def dm_message_params
    params.require(:message).permit(:content, :area_id, :target_character_id)
  end

  def create_witnesses_for_dm_message(message)
    if message.area_id.present?
      # Area-based message
      characters_in_area = @game.characters.where(area_id: message.area_id)
      characters_in_area.each do |character|
        message.message_witnesses.create(character: character)
      end
    elsif params[:message][:target_character_id].present?
      # Private message to specific character
      target_character = @game.characters.find_by(id: params[:message][:target_character_id])
      if target_character
        message.message_witnesses.create(character: target_character)
        message.message_witnesses.create(character: @dm_character) if @dm_character != target_character
      end
    else
      # Broadcast to all
      @game.characters.each do |character|
        message.message_witnesses.create(character: character)
      end
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