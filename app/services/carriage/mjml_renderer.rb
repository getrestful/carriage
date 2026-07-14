module Carriage
  class TemplateRenderError < StandardError; end

  # Wraps whichever MJML-to-HTML gem is configured (currently mrml — a Rust
  # reimplementation with no ActionView/Rails integration of its own, so
  # requiring it has no side effects on the host app's template handling) so
  # the rest of Carriage only ever calls this one method to go from MJML to
  # HTML.
  class MjmlRenderer
    def self.render(mjml_source)
      new.render(mjml_source)
    end

    def render(mjml_source)
      MRML::Template.new(mjml_source).to_html
    rescue MRML::Error => e
      raise TemplateRenderError, e.message
    end
  end
end
