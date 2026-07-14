require_relative "lib/carriage/version"

Gem::Specification.new do |spec|
  spec.name        = "carriage"
  spec.version     = Carriage::VERSION
  spec.authors     = [ "Stefan" ]
  spec.email       = [ "stefan@getrestful.ch" ]
  spec.homepage    = "https://github.com/getrestful/carriage"
  spec.summary     = "Embeddable email newsletter engine for Rails apps."
  spec.description = "Carriage is a mountable Rails engine that adds email newsletter " \
    "functionality (lists, campaigns, MJML templating, open/click tracking) to any host app."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "mailkick", "~> 2.0"
  spec.add_dependency "mrml", "~> 1.10"
  spec.add_dependency "csv"
  spec.add_dependency "image_processing", "~> 2.0"
  spec.add_dependency "lucide-rails", "~> 0.7"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "letter_opener"
  spec.add_development_dependency "tailwindcss-ruby", "~> 4.0"
end
