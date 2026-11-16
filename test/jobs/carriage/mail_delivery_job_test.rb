require "test_helper"

module Carriage
  class MailDeliveryJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper

    setup do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      @subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)
    end

    test "confirmation emails are enqueued with Carriage's retrying delivery job" do
      assert_enqueued_with(job: Carriage::MailDeliveryJob) do
        @subscription.send_confirmation_email
      end
    end

    test "schedules a retry when delivery raises" do
      failing_confirmation_mailer do
        assert_enqueued_with(job: Carriage::MailDeliveryJob) do
          build_job.perform_now
        end
      end
    end

    test "raises once the configured attempts are used up" do
      job = build_job
      job.exception_executions = { "[StandardError]" => Carriage.delivery_attempts - 1 }

      failing_confirmation_mailer do
        assert_no_enqueued_jobs do
          error = assert_raises(RuntimeError) { job.perform_now }
          assert_equal "boom", error.message
        end
      end
    end

    test "is dropped without a retry when the subscription no longer exists" do
      @subscription.send_confirmation_email
      job = enqueued_jobs.last
      @subscription.subscriber.destroy!
      clear_enqueued_jobs

      assert_no_enqueued_jobs do
        assert_nothing_raised { ActiveJob::Base.execute(job) }
      end
    end

    private

    def build_job
      Carriage::MailDeliveryJob.new("Carriage::ConfirmationMailer", "confirm_email", "deliver_now", args: [ @subscription ])
    end

    def failing_confirmation_mailer
      Carriage::ConfirmationMailer.define_singleton_method(:confirm_email) { |_subscription| raise "boom" }
      yield
    ensure
      Carriage::ConfirmationMailer.singleton_class.send(:remove_method, :confirm_email)
    end
  end
end
