module Carriage
  class Engine < ::Rails::Engine
    isolate_namespace Carriage

    config.generators do |g|
      g.test_framework :minitest, spec: false, fixture: false
      g.assets false
      g.helper false
    end

    initializer "carriage.mjml_mime_type" do
      Mime::Type.register "text/mjml", :mjml unless Mime::Type.lookup_by_extension(:mjml)
    end

    # Carriage intentionally does not configure ActionMailer delivery here —
    # Carriage::ApplicationMailer inherits the host app's existing config.action_mailer settings.
  end
end
