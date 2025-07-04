class Games::DmMessagesController < ApplicationController
  before_action :set_game

  def create
    @message = @game.messages.build(dm_message_params)
    # DM messages have no character (they're from the system/DM)
    @message.character = nil
    @message.message_type = params[:message][:message_type] || "system"

    # Handle different target types
    target_type = params[:message][:target_type]
    case target_type
    when "character"
      @message.target_character_id = params[:message][:target_character_id]
      @message.area_id = nil
    when "all"
      @message.target_character_id = nil
      @message.area_id = nil
    when "area"
      # area_id is already set from dm_message_params
      @message.target_character_id = nil
    end

    if @message.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "games/messages/message", locals: { message: @message, player_character: nil, is_dm_view: true }) }
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

  def dm_message_params
    params.require(:message).permit(:content, :area_id)
  end
end
