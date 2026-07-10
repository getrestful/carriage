module Carriage
  module Public
    # Base for every controller mounted via Carriage::Public::Engine — public,
    # unauthenticated endpoints embedded in outgoing email (tracking pixel,
    # click redirect, unsubscribe) or linked from the host app's own pages
    # (signup, opt-in confirmation). Deliberately a separate mount point from
    # Carriage::Engine so a host app can wrap the admin engine in its own auth
    # while leaving this one reachable by anonymous visitors — see README.
    class ApplicationController < ActionController::Base
      layout "carriage/public"

      # Deliberately does NOT skip forgery protection: TrackingController,
      # UnsubscribesController, and ConfirmationsController are GET-only (Rails
      # doesn't require a CSRF token for GET), but SignupsController#create is a
      # real state-changing POST — without the default protection, a third-party
      # site could script mass signups (spamming arbitrary email addresses onto
      # a host's list) without ever loading Carriage's own form. The form in
      # signups/new.html.erb already emits the token via form_with, so this is
      # a no-op change for every legitimate caller.
    end
  end
end
