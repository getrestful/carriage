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

  # How many times Carriage tries to hand a mail (campaign or confirmation) to
  # the host's delivery method before giving up. Waits grow polynomially
  # (~3s, 18s, 83s, 4m, 10m, 22m, 40m, 68m, 109m), so the default of 10 keeps
  # trying for a bit over 4 hours — enough to ride out a provider outage of an
  # hour or two. Read when the job classes load, so set it in an initializer.
  mattr_accessor :delivery_attempts
  self.delivery_attempts = 10
end
