require "csv"

module Carriage
  class CsvImport
    Result = Struct.new(:created, :skipped, :invalid, keyword_init: true)

    def initialize(list, file_path, mapping)
      @list = list
      @file_path = file_path
      @mapping = mapping
    end

    def call
      created = skipped = invalid = 0

      CSV.foreach(@file_path, headers: true) do |row|
        email = row[@mapping["email"]]&.strip&.downcase

        if email.blank? || !email.match?(URI::MailTo::EMAIL_REGEXP)
          invalid += 1
          next
        end

        subscriber = Carriage::Subscriber.find_or_initialize_by(email: email)
        subscriber.first_name = row[@mapping["first_name"]] if @mapping["first_name"].present?
        subscriber.last_name = row[@mapping["last_name"]] if @mapping["last_name"].present?

        # Custom field columns are matched by name against the list's own schema, no mapping UI.
        @list.field_names.each do |field_name|
          next unless row.headers.include?(field_name)
          subscriber.custom_fields = subscriber.custom_fields.merge(field_name => row[field_name])
        end

        subscriber.save!

        subscription = Carriage::Subscription.find_or_create_by(list: @list, subscriber: subscriber)
        if subscription.previously_new_record?
          created += 1
        else
          skipped += 1
        end
      end

      Result.new(created: created, skipped: skipped, invalid: invalid)
    end
  end
end
