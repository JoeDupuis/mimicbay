class Games::PlayController < ApplicationController
  before_action :set_game
  before_action :set_active_character

  def show
    @messages = @active_character.witnessed_messages_in_order
    @message = @game.messages.build
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def set_active_character
    if params[:character_id].present?
      @active_character = @game.characters.find(params[:character_id])
      @is_impersonating = true
    else
      @active_character = @game.characters.player.first
      @is_impersonating = false
      redirect_to @game, alert: "No player character found" unless @active_character
    end
  end
end
