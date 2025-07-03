class CharactersController < ApplicationController
  before_action :set_game
  before_action :set_character, only: %i[show edit update destroy]

  def index
    @characters = @game.characters
  end

  def show
  end

  def new
    @character = @game.characters.build
  end

  def create
    @character = @game.characters.build(character_params)

    if @character.save
      redirect_to game_characters_path(@game), notice: success_message(@character)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @character.update(character_params)
      redirect_to game_character_path(@game, @character), notice: success_message(@character)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @character.destroy!
    redirect_to game_characters_path(@game), notice: success_message(@character)
  end

  private

  def set_game
    @game = Current.user.games.find(params[:game_id])
  end

  def set_character
    @character = @game.characters.find(params[:id])
  end

  def character_params
    params.require(:character).permit(:name, :description, :properties, :is_player, :area_id)
  end
end
