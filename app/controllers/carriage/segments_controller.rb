module Carriage
  class SegmentsController < ApplicationController
    before_action :set_segment, only: [ :show, :edit, :update, :destroy ]

    def index
      @segments = Carriage::Segment.includes(:list).order(:name)
    end

    def show
      @subscribers = @segment.subscribers.order(:email).limit(20)
      @subscriber_count = @segment.active_subscribers.count
    end

    def new
      @segment = Carriage::Segment.new(list_id: params[:list_id])
    end

    def create
      @segment = Carriage::Segment.new(segment_params)
      if @segment.save
        redirect_to @segment, notice: "Segment created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @segment.update(segment_params)
        redirect_to @segment, notice: "Segment updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @segment.destroy
      redirect_to segments_path, notice: "Segment deleted."
    end

    private

    def set_segment
      @segment = Carriage::Segment.find(params[:id])
    end

    def segment_params
      params.require(:segment).permit(:list_id, :name, :match_type, :conditions_text)
    end
  end
end
