class Games::MessagesController < ApplicationController
  before_action :set_game
  before_action :set_player_character

  def create
    @message = @game.messages.build(message_params)
    @message.character = @player_character
    @message.area = @player_character.area
    @message.message_type = "chat"

    if @message.save
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
end
