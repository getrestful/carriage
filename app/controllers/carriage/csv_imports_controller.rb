require "csv"

module Carriage
  class CsvImportsController < ApplicationController
    before_action :set_list

    def new
    end

    def create
      uploaded = params.require(:file)
      headers = CSV.open(uploaded.tempfile.path, &:readline)

      mapping = {
        "email" => params[:email_column].presence || (headers.include?("email") ? "email" : headers.first),
        "first_name" => params[:first_name_column].presence || (headers.include?("first_name") ? "first_name" : nil),
        "last_name" => params[:last_name_column].presence || (headers.include?("last_name") ? "last_name" : nil)
      }

      result = Carriage::CsvImport.new(@list, uploaded.tempfile.path, mapping).call
      redirect_to list_path(@list),
        notice: "Import complete: #{result.created} added, #{result.skipped} already on this list, #{result.invalid} invalid rows skipped."
    rescue ActionController::ParameterMissing, CSV::MalformedCSVError
      redirect_to new_list_csv_import_path(@list), alert: "Please upload a valid CSV file."
    end

    private

    def set_list
      @list = Carriage::List.find(params[:list_id])
    end
  end
end
