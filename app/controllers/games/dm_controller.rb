class Games::DmController < ApplicationController
  before_action :set_game
  before_action :ensure_game_owner

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

  def ensure_game_owner
    # Since we're finding the game through Current.user.games,
    # we already know the user owns this game
    # This is here for clarity and potential future expansion
  end
end
