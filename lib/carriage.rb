require "active_support/core_ext/module/attribute_accessors"
require "mailkick"
require "mjml-rb"
require "lucide-rails"
require "carriage/version"
require "carriage/engine"
require "carriage/public/engine"

module Carriage
  mattr_accessor :default_from_address
  self.default_from_address = "no-reply@example.com"
end
