require "active_support/core_ext/module/attribute_accessors"
require "mailkick"
require "mrml"
require "lucide-rails"
require "carriage/version"
require "carriage/engine"
require "carriage/public/engine"

module Carriage
  mattr_accessor :default_from_address
  self.default_from_address = "no-reply@example.com"

  # Attempts per mail; 10 spans a bit over 4 hours. Set it in an initializer.
  mattr_accessor :delivery_attempts
  self.delivery_attempts = 10
end
