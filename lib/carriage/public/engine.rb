module Carriage
  module Public
    # Separate mountable engine for Carriage's public, unauthenticated
    # endpoints (tracking pixel, click redirect, unsubscribe, signup,
    # opt-in confirmation) — kept apart from Carriage::Engine (the admin UI)
    # so a host app can wrap only the admin engine in its own auth:
    #
    #   authenticate :user, ->(u) { u.admin? } do
    #     mount Carriage::Engine => "/carriage"
    #   end
    #   mount Carriage::Public::Engine => "/c"
    #
    # isolate_namespace'd separately from Carriage::Engine (a namespace can
    # only be isolated by one engine) so its own route helpers, views, and
    # generators stay scoped to Carriage::Public::* rather than colliding
    # with the admin engine's.
    class Engine < ::Rails::Engine
      isolate_namespace Carriage::Public

      config.paths["config/routes.rb"] = "config/public_routes.rb"

      config.generators do |g|
        g.test_framework :minitest, spec: false, fixture: false
        g.assets false
        g.helper false
      end
    end
  end
end
