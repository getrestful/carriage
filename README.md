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
