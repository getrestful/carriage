require "csv"

module Carriage
  class CsvExport
    def initialize(list)
      @list = list
    end

    def call
      field_names = @list.field_names

      CSV.generate(headers: true) do |csv|
        csv << [ "email", "first_name", "last_name", "status", *field_names ]
        @list.subscribers.order(:email).each do |subscriber|
          status = subscriber.subscribed?(@list.name) ? "subscribed" : "unsubscribed"
          csv << [ subscriber.email, subscriber.first_name, subscriber.last_name, status,
                    *field_names.map { |name| subscriber.custom_fields[name] } ]
        end
      end
    end
  end
end
