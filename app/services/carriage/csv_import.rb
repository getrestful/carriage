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

        # Custom field columns are matched by name against the list's own schema, no mapping UI.
        custom_fields = @list.field_names.each_with_object({}) do |field_name, memo|
          memo[field_name] = row[field_name] if row.headers.include?(field_name)
        end

        subscription = @list.add_subscriber(
          email: email,
          first_name: (row[@mapping["first_name"]] if @mapping["first_name"].present?),
          last_name: (row[@mapping["last_name"]] if @mapping["last_name"].present?),
          custom_fields: custom_fields
        )

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
