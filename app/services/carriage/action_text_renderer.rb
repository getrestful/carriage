module Carriage
  # Action Text installs an `around_action` (on both action_controller_base and
  # action_mailer) that points ActionText::Content.renderer at whichever
  # controller/mailer is currently processing a request. Since Carriage is an
  # isolate_namespace engine, that renderer is Carriage's own isolated route
  # set — which has no idea about ActiveStorage's routes, so embedded images
  # in campaign body_html fail to resolve to a URL from inside
  # Carriage::CampaignMailer or Carriage::CampaignsController#preview.
  # Rendering body_html always needs the host app's main route set instead.
  module ActionTextRenderer
    def self.renderer
      @renderer ||= Class.new(ActionController::Base).renderer
    end
  end
end
