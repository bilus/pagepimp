class ThemesController < ApplicationController
  # GET /themes
  # GET /themes.json
  def index

    @tags = ActsAsTaggableOn::Tag.
        group("tags.name").
        select("tags.name")

    if params[:search]
      @themes = Theme.visible_for(current_user).search(params[:search]).page(params[:page]).per_page(15)
    else
      if params[:tag]
        @themes = Theme.visible_for(current_user).tagged_with(params[:tag]).page(params[:page]).per_page(15)
      else
        @themes = Theme.visible_for(current_user).page(params[:page]).per_page(15)
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @themes }
      format.js
    end
  end

  # GET /themes/1
  # GET /themes/1.json
  def show
    @theme = Theme.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @theme }
    end
  end

  # GET /themes/new
  # GET /themes/new.json
  def new
    @theme = Theme.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @theme }
    end
  end

  # GET /themes/1/edit
  def edit
    @theme = Theme.find(params[:id])
  end

  # POST /themes
  # POST /themes.json
  def create
    @theme = Theme.new(params[:theme])

    respond_to do |format|
      if @theme.save
        format.html { redirect_to @theme, notice: 'Theme was successfully created.' }
        format.json { render json: @theme, status: :created, location: @theme }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /themes/1
  # PUT /themes/1.json
  def update
    @theme = Theme.find(params[:id])

    respond_to do |format|
      if @theme.update_attributes(params[:theme])
        format.html { redirect_to @theme, notice: 'Theme was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /themes/1
  # DELETE /themes/1.json
  def destroy
    @theme = Theme.find(params[:id])
    @theme.destroy

    respond_to do |format|
      format.html { redirect_to themes_url }
      format.json { head :no_content }
    end
  end

  def toggle_active
    @theme = Theme.find(params[:id])
    if @theme.active?
      @theme.active = false
    else
      @theme.active = true
    end
    @theme.save!

    respond_to do |format|
      format.js
    end
  end
end
