class Games::PlayController < ApplicationController
  before_action :set_game
  before_action :set_player_character

  def show
    @messages = @player_character.witnessed_messages_in_order
    @message = @game.messages.build
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def set_player_character
    @player_character = @game.characters.player.first
    redirect_to @game, alert: "No player character found" unless @player_character
  end
end
