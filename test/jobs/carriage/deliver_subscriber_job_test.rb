require "test_helper"

module Carriage
  class DeliverSubscriberJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper

    test "delivers the mail and marks the delivery sent" do
      list = Carriage::List.create!(name: "Weekly")
      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi", body_html: "<p>hi</p>")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      delivery = Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber)

      assert_emails 1 do
        Carriage::DeliverSubscriberJob.perform_now(delivery.id)
      end

      assert delivery.reload.sent?
      assert delivery.sent_at.present?
    end

    test "marks the delivery retrying and schedules a retry on mailer error" do
      delivery = create_delivery

      failing_campaign_mailer do
        assert_enqueued_with(job: Carriage::DeliverSubscriberJob) do
          Carriage::DeliverSubscriberJob.perform_now(delivery.id)
        end
      end

      assert delivery.reload.retrying?
      assert_equal "boom", delivery.error_message
    end

    test "marks the delivery failed and raises once the attempts are used up" do
      delivery = create_delivery
      job = Carriage::DeliverSubscriberJob.new(delivery.id)
      job.exception_executions = { "[StandardError]" => Carriage.delivery_attempts - 1 }

      failing_campaign_mailer do
        assert_no_enqueued_jobs do
          assert_raises(RuntimeError) { job.perform_now }
        end
      end

      assert delivery.reload.failed?
      assert_equal "boom", delivery.error_message
    end

    test "a retry that succeeds marks the delivery sent" do
      delivery = create_delivery
      delivery.update!(state: :retrying, error_message: "boom")

      assert_emails 1 do
        Carriage::DeliverSubscriberJob.perform_now(delivery.id)
      end

      assert delivery.reload.sent?
    end

    private

    def create_delivery
      list = Carriage::List.create!(name: "Weekly")
      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi", body_html: "<p>hi</p>")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber)
    end

    def failing_campaign_mailer
      Carriage::CampaignMailer.define_singleton_method(:campaign_email) { |_delivery| raise "boom" }
      yield
    ensure
      Carriage::CampaignMailer.singleton_class.send(:remove_method, :campaign_email)
    end
  end
end
