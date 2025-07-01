class GamesController < ApplicationController
  include NoticeI18n

  before_action :set_game, only: %i[show edit update destroy]

  def index
    @games = Current.user.games
  end

  def show
  end

  def new
    @game = Current.user.games.build
  end

  def create
    @game = Current.user.games.build(game_params)

    if @game.save
      redirect_to @game, notice: success_message(@game)
    else
      flash.now[:alert] = failure_message(@game)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @game.update(game_params)
      redirect_to @game, notice: success_message(@game)
    else
      flash.now[:alert] = failure_message(@game)
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
    params.require(:game).permit(:name)
  end
end
