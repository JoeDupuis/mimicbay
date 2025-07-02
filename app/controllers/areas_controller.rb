class AreasController < ApplicationController
  before_action :set_game
  before_action :set_area, only: %i[show edit update destroy]

  def index
    @areas = @game.areas
  end

  def show
  end

  def new
    @area = @game.areas.build
  end

  def create
    @area = @game.areas.build(area_params)

    if @area.save
      redirect_to game_areas_path(@game), notice: "Area was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @area.update(area_params)
      redirect_to game_area_path(@game, @area), notice: "Area was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @area.destroy!
    redirect_to game_areas_path(@game), notice: "Area was successfully destroyed."
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def set_area
    @area = @game.areas.find(params[:id])
  end

  def area_params
    params.require(:area).permit(:name, :description, :properties)
  end
end
