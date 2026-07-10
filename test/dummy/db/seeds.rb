Carriage::List.find_or_create_by!(name: "Product Updates") do |list|
  list.description = "Demo list used by the dummy app's homepage signup form."
end
