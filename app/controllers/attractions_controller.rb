class AttractionsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :search]

  def index
    @attractions = Attraction.order(created_at: :desc).page params[:page]
    if current_user
      gon.user = current_user
      @visited_attractions = current_user.visited_attractions.pluck(:id)
    end
  end

  def show
    @attraction = Attraction.find(params[:id])
    @key = ENV['MAPS_KEY']
    @adobe_key = ENV['ADOBE_DEV_ID']
    @base_url = 'https://www.google.com/maps/embed/v1/view'
    if @attraction.latitude
      @lat = @attraction.latitude
      @long = @attraction.longitude
      @iframe_source = "#{@base_url}?key=#{@key}&center=#{@lat},#{@long}&zoom=18"
    else
      @iframe_source = "#{@base_url}?key=#{@key}&center=39.8282,-98.5795"
    end
  end

  def new
    @attraction = Attraction.new
  end

  def create
    @attraction = Attraction.new(attraction_params)
    @attraction.creator = current_user
    if @attraction.save
      flash[:notice] = "You added a photo!"
      redirect_to attraction_path(@attraction)
    else
      flash[:alert] = @attraction.errors.full_messages.join(', ')
      render :new
    end
  end

  def edit
    @attraction = Attraction.find(params[:id])
  end

  def update
    @attraction = Attraction.find(params[:id])
    if @attraction.update(attraction_params)
      flash[:notice] = 'You updated your photo details'
      redirect_to attraction_path(@attraction)
    else
      flash[:alert] = @attraction.errors.full_messages.join(', ')
      render :edit
    end
  end

  def search
    @query = params[:query]
    @distance = Integer(params[:distance]) rescue false
    if !@distance
      @distance = 10
    end
    @search_results = Attraction.near(@query, @distance)
  end

  def update_photo
    @attraction = Attraction.find(params[:id])
    if  @attraction.add_remote_photo(params[:url_to_save])
      render json: {message: 'success'}
    else
      render json: {message: 'failure'}
    end
  end

  private

  def attraction_params
    params.require(:attraction).permit(:name, :photo, :description)
  end
end
