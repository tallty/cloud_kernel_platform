module Admin
  class StationInfosController < ApplicationController
    before_action :set_station_info, only: [:show, :edit, :update, :destroy]

    # GET /station_infos
    # GET /station_infos.json
    def index
      @station_infos = StationInfo.all
    end

    # GET /station_infos/1
    # GET /station_infos/1.json
    def show
    end

    # GET /station_infos/new
    def new
      @station_info = StationInfo.new
    end

    # GET /station_infos/1/edit
    def edit
    end

    # POST /station_infos
    # POST /station_infos.json
    def create
      @station_info = StationInfo.new(station_info_params)

      respond_to do |format|
        if @station_info.save
          format.html { redirect_to @station_info, notice: 'Station info was successfully created.' }
          format.json { render :show, status: :created, location: @station_info }
        else
          format.html { render :new }
          format.json { render json: @station_info.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /station_infos/1
    # PATCH/PUT /station_infos/1.json
    def update
      respond_to do |format|
        if @station_info.update(station_info_params)
          format.html { redirect_to @station_info, notice: 'Station info was successfully updated.' }
          format.json { render :show, status: :ok, location: @station_info }
        else
          format.html { render :edit }
          format.json { render json: @station_info.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /station_infos/1
    # DELETE /station_infos/1.json
    def destroy
      @station_info.destroy
      respond_to do |format|
        format.html { redirect_to station_infos_url, notice: 'Station info was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_station_info
        @station_info = StationInfo.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def station_info_params
        params[:station_info]
      end
  end
end
