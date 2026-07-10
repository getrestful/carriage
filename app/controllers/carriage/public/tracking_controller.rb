require "base64"

module Carriage
  module Public
    class TrackingController < ApplicationController
      PIXEL_GIF = Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBTAA7").freeze

      def open
        delivery = Carriage::Delivery.find_by(token: params[:token])
        delivery&.register_open!

        send_data PIXEL_GIF, type: "image/gif", disposition: "inline"
      end

      def click
        click = Carriage::Click.find_by(token: params[:token])

        if click
          click.register_click!
          redirect_to click.url, allow_other_host: true
        else
          head :not_found
        end
      end
    end
  end
end
