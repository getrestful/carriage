module Carriage
  class TemplateRenderError < StandardError; end

  # Wraps whichever MJML-to-HTML gem is configured (currently mjml-rb) so the
  # rest of Carriage only ever calls this one method to go from MJML to HTML.
  class MjmlRenderer
    def self.render(mjml_source)
      new.render(mjml_source)
    end

    def render(mjml_source)
      result = MjmlRb::Compiler.new(validation_level: "skip").compile(mjml_source)
      raise TemplateRenderError, result.errors.map { |e| e[:formatted_message] || e[:message] }.join(", ") if result.errors.any?

      result.html
    end
  end
end
