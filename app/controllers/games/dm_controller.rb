class Games::DmController < ApplicationController
  before_action :set_game

  def show
    @characters = @game.characters
    @areas = @game.areas
    @messages = @game.messages.includes(:character, :area, :witnesses).order(created_at: :asc)
    @message = @game.messages.build
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end
end
