class Games::MessagesController < ApplicationController
  before_action :set_game
  before_action :authorize_impersonation
  before_action :set_active_character

  def create
    @message = @game.messages.build(message_params)
    @message.character = @active_character
    @message.area = @active_character.area
    @message.message_type = "chat"

    if @message.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "games/messages/message", locals: { message: @message }) }
        format.html { redirect_to game_play_path(@game, character_id: params[:character_id]) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_message_form", partial: "games/messages/form", locals: { game: @game, message: @message }) }
        format.html { redirect_to game_play_path(@game, character_id: params[:character_id]), alert: @message.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def authorize_impersonation
    if params[:character_id].present?
      unless @game.user == Current.user
        redirect_to game_play_path(@game), alert: "Only the game master can impersonate characters"
      end
    end
  end

  def set_active_character
    if params[:character_id].present? && @game.user == Current.user
      @active_character = @game.characters.find(params[:character_id])
    else
      @active_character = @game.characters.player.first
      redirect_to game_play_path(@game), alert: "No player character found" unless @active_character
    end
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
