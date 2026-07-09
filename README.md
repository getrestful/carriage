# Carriage

Carriage is a mountable Rails engine that adds email newsletter functionality —
lists, subscribers, MJML-templated campaigns, test/scheduled/list sends, and
open/click stats — to any host Rails app. It uses the host app's own
ActionMailer configuration to actually deliver mail; Carriage has no SMTP
config of its own.

v1 ships a single static template with a field-based campaign editor
(subject/heading/body/CTA/footer). Drag-and-drop editing, multiple templates,
segmentation, and bounce handling are not in scope yet — see "Deferred to v2"
below.

## Installation

Add to your host app's Gemfile:

```ruby
gem "carriage"
```

Then:

```bash
bundle install
bin/rails carriage:install:migrations
bin/rails db:migrate
```

`carriage:install:migrations` also copies mailkick's own `mailkick_subscriptions`
migration, since Carriage uses [mailkick](https://github.com/ankane/mailkick)
for per-list subscribe/unsubscribe bookkeeping.

Mount the engine and add your own authentication around it — Carriage ships
with **zero** built-in auth:

```ruby
# config/routes.rb
authenticate :user, ->(u) { u.admin? } do
  mount Carriage::Engine => "/carriage"
end
```

Set a default From address and make sure `config.action_mailer.default_url_options`
(host) is set — Carriage's tracking links and unsubscribe links need it:

```ruby
# config/initializers/carriage.rb
Carriage.default_from_address = "news@yourapp.com"
```

### Scheduling campaign sends

Carriage does not bundle a scheduler. Add a periodic call to the host app's
scheduler of choice (whenever, Heroku Scheduler, sidekiq-cron, GoodJob/Solid
Queue recurring tasks, plain cron, ...), running at least once a minute:

```bash
bin/rails carriage:deliver_due_campaigns
```

This rake task only *enqueues* `Carriage::DeliverCampaignJob` via ActiveJob —
if your host app uses the in-process `:async` adapter (Rails' dev default),
a short-lived rake-task process may exit before the enqueued job runs. Use a
persistent adapter (Sidekiq, GoodJob, Solid Queue, etc.) for reliable delivery
in production.

## How tracking works

Carriage does **not** use ahoy_matey/ahoy_email for opens/clicks — that gem
dropped open tracking entirely in v2.0 (click-only). Instead, Carriage embeds
its own open-tracking pixel and rewrites outgoing links through its own
click-redirect endpoint, recording both directly against `Carriage::Delivery`
and `Carriage::Click`. Unsubscribe links are Carriage's own (token-based,
keyed off `Carriage::Delivery#token`), with `mailkick`'s subscribe/unsubscribe
bookkeeping kept in sync as a courtesy. `Carriage::Subscription#unsubscribed_at`
is the durable source of truth for opt-out (mailkick itself has no persistent
opt-out state — its "unsubscribe" is a hard delete, which would otherwise let
a re-import silently resubscribe someone).

## Rich text campaign body

The campaign body field uses Action Text (Trix) instead of a plain textarea,
so editors get bold/links/lists/images without a drag-and-drop block builder.
This has host-app implications worth knowing about, since Action Text and
Active Storage are **not** isolated the way Carriage's own tables are —
`Carriage::Campaign#body_html` is backed by `action_text_rich_texts` and
`active_storage_*` tables that live in your host app's database and aren't
shipped by `carriage:install:migrations`.

Host app setup (one-time, in addition to the "Installation" steps above):

```bash
bin/rails action_text:install   # copies action_text/active_storage migrations,
                                 # config/storage.yml, and JS/CSS wiring
bin/rails active_storage:install  # only needed if action_text:install didn't run it
bin/rails db:migrate
```

Also add `image_processing` to your host app's Gemfile (Carriage depends on
it for rendering the thumbnail previews Action Text embeds for uploaded
images) and make sure a processor is available at runtime — either
[libvips](https://www.libvips.org/) or ImageMagick.

Two host-app config points that are easy to miss:

- **Set `Rails.application.routes.default_url_options[:host]`, not just
  `config.action_mailer.default_url_options`.** Action Text renders embedded
  images as `<img>` tags via Active Storage's own URL helpers, which read
  from the router's `default_url_options`, not ActionMailer's. Set both to
  the same host or campaign emails will render with broken image links
  (silently falling back to a bogus `http://example.org` host) even though
  the CTA/unsubscribe links work fine.
- **Don't set a short `config.active_storage.urls_expire_in`.** Campaign
  emails can sit in an inbox for weeks before being opened; a short expiry on
  the embedded image URLs will break images in mail that's already been
  sent. Leave it at its default (no expiry). Consider
  `config.active_storage.resolve_model_to_route = :rails_storage_proxy`
  (serves image bytes through your app instead of redirecting to the
  storage service) if you'd rather not expose signed cloud-storage URLs
  directly in outgoing email.

Carriage's own layout (`app/views/layouts/carriage/application.html.erb`)
ships the Trix/Action Text JS and CSS tags directly, so no host-app asset
config is needed to get the editor UI working in `/carriage`. Action Text's
default attachment-rendering views (used both for the editor and for
`body_html.to_s` in the mailer) are left untouched — Carriage doesn't
override them, so they always match whatever `actiontext` gem version the
host app resolves to.

**`isolate_namespace` + Action Text's attachment rendering needs a workaround.**
Action Text installs an `around_action` (on both controllers and mailers)
that points `ActionText::Content.renderer` at whatever controller/mailer is
currently handling the request — but Carriage is `isolate_namespace`d, so
inside `Carriage::CampaignMailer` and `Carriage::CampaignsController#preview`
that renderer is Carriage's own isolated route set, which has no knowledge of
Active Storage's routes. Left alone, embedded images in `body_html` would
fail to resolve to a URL (`undefined method 'to_model' for an instance of
ActiveStorage::VariantWithRecord`) whenever a campaign is previewed or
actually sent — but render fine anywhere else, which makes it easy to miss
in ad-hoc testing. `Carriage::ActionTextRenderer` (a plain, non-isolated
`ActionController::Base` renderer) is used to wrap both render calls so
attachment URLs resolve against the host app's main route set instead.

## MJML rendering

Templates are compiled via [mjml-rb](https://github.com/awarwick/mjml-rb), a
pure-Ruby MJML port (no Node.js dependency). It's marked experimental by its
author — not all MJML components may render identically to the official
Node-based compiler. The rendering call is isolated in
`Carriage::MjmlRenderer`, so swapping renderers later only touches one file.

## Development

```bash
bin/rails db:migrate   # migrate the dummy app at test/dummy
bin/rails test         # run the test suite
bin/rails server       # boot the dummy app to click through the admin UI at /carriage
```

The dummy app's development environment uses `letter_opener` to preview sent
mail in a browser instead of actually delivering it.

## Deferred to v2

- Drag-and-drop / block-based visual campaign editor
- Multiple selectable templates
- Per-user auth/roles within Carriage itself
- A/B testing
- Bounce/complaint webhook handling
- List segmentation
- Double opt-in flows
- Background/chunked processing of very large CSV imports

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
