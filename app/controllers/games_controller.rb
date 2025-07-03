class GamesController < ApplicationController
  before_action :set_game, only: %i[show edit update destroy]

  def index
    @games = Current.user.games
  end

  def show
    redirect_to game_play_path(@game) if @game.playing?
  end

  def new
    @game = Current.user.games.build
  end

  def create
    @game = Current.user.games.build(game_params)

    if @game.save
      redirect_to @game, notice: success_message(@game)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if changing_to_playing_state? && !@game.characters.player.exists?
      redirect_to @game, alert: "You must create a player character before starting the game."
    elsif @game.update(game_params)
      redirect_to @game, notice: success_message(@game)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy!
    redirect_to games_url, notice: success_message(@game)
  end

  private

  def set_game
    @game = Current.user.games.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:name, :state)
  end

  def changing_to_playing_state?
    game_params[:state] == "playing" && @game.creating?
  end
end
