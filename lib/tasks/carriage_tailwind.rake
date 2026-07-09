namespace :carriage do
  desc "Compile Carriage's admin UI stylesheet from Tailwind source (development only; output is committed and shipped with the gem)"
  task :build_css do
    require "tailwindcss/ruby"

    root = File.expand_path("../..", __dir__)
    input = File.join(root, "app/assets/tailwind/carriage/application.tailwind.css")
    output = File.join(root, "app/assets/stylesheets/carriage/application.css")

    command = [ Tailwindcss::Ruby.executable, "-i", input, "-o", output, "--minify" ]
    puts "Running: #{command.join(' ')}"
    system(*command, exception: true)
  end
end
