class Games::DmController < ApplicationController
  before_action :set_game
  before_action :set_dm_character

  def show
    @characters = @game.characters.non_player
    @areas = @game.areas
    @messages = @dm_character.witnessed_messages_in_order
    @message = @game.messages.build
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def set_dm_character
    @dm_character = @game.characters.dm.first
    unless @dm_character
      redirect_to @game, alert: "You need a DM character to access the DM interface"
    end
  end
end