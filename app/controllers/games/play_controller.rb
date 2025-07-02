class Games::PlayController < ApplicationController
  before_action :set_game

  def show
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end
end
