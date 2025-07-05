class Games::ConfigurationsController < ApplicationController
  before_action :set_game
  before_action :ensure_game_creating
  before_action :set_or_create_session

  def show
    @messages = @session.messages.includes(:game_configuration_session)
    @available_models = LLM::MODELS.map { |m| [ m[:name], m[:id] ] }
    @default_model = LLM::MODELS.first[:id]
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
