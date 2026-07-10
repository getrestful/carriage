module Carriage
  # Post-processes Action Text's rendered body_html for email: constrains
  # embedded images to the body width, hides the auto-generated
  # "filename (size)" figcaption Action Text prints when the editor never
  # set an explicit caption, and styles a real caption (light grey,
  # centered) since email has no external stylesheet to do it for us.
  # Nokogiri-based rather than an MJML/CSS rule because Carriage
  # deliberately doesn't ship a frozen copy of Action Text's attachment
  # partial (see CLAUDE.md) and mjml-rb's CSS inliner (css_parser) doesn't
  # support the :has() selector this would need.
  class CampaignBodyRenderer
    def self.for_email(body_html)
      new(body_html).call
    end

    def initialize(body_html)
      @body_html = body_html
    end

    def call
      doc = Nokogiri::HTML5.fragment(@body_html.to_s)

      doc.css("img").each do |img|
        img.remove_attribute("width")
        img.remove_attribute("height")
        img["style"] = [ img["style"], "max-width:100%;height:auto;" ].compact.join(";")
      end
      doc.css("figcaption.attachment__caption").each do |caption|
        if caption.at_css(".attachment__name")
          caption.remove
        else
          caption["style"] = "color:#999999;text-align:center;margin-top:8px;font-size:12px;"
        end
      end

      doc.to_html
    end
  end
end
