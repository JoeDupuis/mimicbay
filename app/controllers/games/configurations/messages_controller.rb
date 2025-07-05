class Games::Configurations::MessagesController < ApplicationController
  before_action :set_game
  before_action :ensure_game_creating
  before_action :set_or_create_session

  def create
    @session.prompt(params[:content], model: params[:model])

    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to game_configuration_path(@game) }
    end
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def ensure_game_creating
    redirect_to game_path(@game), alert: "Game configuration is only available during game creation" unless @game.creating?
  end

  def set_or_create_session
    @session = @game.game_configuration_session || @game.create_game_configuration_session!
  end
end
