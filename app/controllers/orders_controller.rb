class OrdersController < ApplicationController

  before_filter :load_theme, except: [:index, :destroy]

  # GET /orders
  # GET /orders.json
  def index

    if user_signed_in?
      @orders = Order.all

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @orders }
      end
    else
      redirect_to themes_path
    end

  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @order = @theme.orders.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.json
  def new
    @order = @theme.orders.build

    respond_to do |format|
      format.html # new.html.erb
      format.js
      format.json { render json: @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @order = @theme.orders.find(params[:id])
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = @theme.orders.new(params[:order])

    respond_to do |format|
      if @order.save
        format.html { redirect_to [@theme, @order], notice: 'Order was successfully created.' }
        format.json { render json: @order, status: :created, location: @order }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.json
  def update
    @order = @theme.orders.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    #@order = @theme.orders.find(params[:id])
    @order = Order.find(params[:id])
    @order.destroy

    respond_to do |format|
      format.html { redirect_to orders_url }
      format.json { head :no_content }
    end
  end

  private

  def load_theme
    @theme = Theme.find(params[:theme_id])
  end
end
