module Carriage
  # Rewrites <a href> links to route through Carriage's click-redirect endpoint
  # and appends an open-tracking pixel, given the compiled HTML for one delivery.
  class EmailTracking
    def self.instrument(html, delivery)
      new(html, delivery).call
    end

    def initialize(html, delivery)
      @html = html
      @delivery = delivery
    end

    def call
      doc = Nokogiri::HTML5.parse(@html)
      rewrite_links(doc)
      insert_open_pixel(doc)
      doc.to_html
    end

    private

    def rewrite_links(doc)
      doc.css("a[href]").each do |link|
        href = link["href"]
        next unless href&.start_with?("http://", "https://")

        if link["data-skip-tracking"]
          link.remove_attribute("data-skip-tracking")
          next
        end

        click = @delivery.clicks.find_or_create_by!(url: href)
        link["href"] = url_helpers.click_url(token: click.token, **url_options)
      end
    end

    def insert_open_pixel(doc)
      body = doc.at_css("body")
      return unless body

      pixel = doc.create_element(
        "img",
        src: url_helpers.open_url(token: @delivery.token, **url_options),
        width: "1", height: "1", alt: "", style: "display:none"
      )
      body.add_child(pixel)
    end

    def url_helpers
      Carriage::Public::Engine.routes.url_helpers
    end

    def url_options
      options = Carriage::ApplicationMailer.default_url_options
      raise Carriage::TrackingConfigError, "config.action_mailer.default_url_options (host) must be set for Carriage tracking links" if options.blank?

      options
    end
  end

  class TrackingConfigError < StandardError; end
end
