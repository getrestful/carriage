module Carriage
  class ListsController < ApplicationController
    before_action :set_list, only: [ :show, :edit, :update, :destroy, :export ]

    def index
      @lists = Carriage::List.order(:name)
    end

    def show
      @subscriptions = @list.subscriptions.includes(:subscriber).order("carriage_subscribers.email").limit(20)
      @subscriber_count = @list.active_subscribers.count
    end

    def new
      @list = Carriage::List.new
    end

    def create
      @list = Carriage::List.new(list_params)
      if @list.save
        redirect_to @list, notice: "List created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @list.update(list_params)
        redirect_to @list, notice: "List updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @list.destroy
      redirect_to lists_path, notice: "List deleted."
    end

    def export
      send_data Carriage::CsvExport.new(@list).call,
        filename: "#{@list.name.parameterize}-subscribers.csv", type: "text/csv"
    end

    private

    def set_list
      @list = Carriage::List.find(params[:id])
    end

    def list_params
      params.require(:list).permit(:name, :description, :fields_text)
    end
  end
end
