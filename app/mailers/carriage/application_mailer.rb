module Carriage
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Carriage.default_from_address }
  end
end
