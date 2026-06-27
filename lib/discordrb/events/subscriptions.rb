# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Generic superclass for subscriptions.
  class SubscriptionEvent < Event
    # @return [Subscription] the subscription associated with the event.
    attr_reader :subscription

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @subscription = Discordrb::Subscription.new(data, @bot)
    end
  end

  # Raised whenever a subscription is created.
  class SubscriptionCreateEvent < SubscriptionEvent; end

  # Raised whenever a subscription is updated.
  class SubscriptionUpdateEvent < SubscriptionEvent; end

  # Raised whenever a subscription is deleted.
  class SubscriptionDeleteEvent < SubscriptionEvent; end

  # Generic event handler for subscriptions.
  class SubscriptionEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(SubscriptionEvent)

      [
        matches_all(@attributes[:id], event.subscription) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:status], event.subscription) do |a, e|
          case a
          when Symbol, String
            Discordrb::Subscription::STATUSES[a.to_sym] == e.status
          else
            a == e.status
          end
        end,

        matches_all(@attributes[:current_period_end], event.subscription) do |a, e|
          a == e.current_period_end
        end,

        matches_all(@attributes[:current_period_start], event.subscription) do |a, e|
          a == e.current_period_start
        end,

        matches_all(@attributes[:user] || @attributes[:user_id], event.subscription) do |a, e|
          a&.resolve_id == e.user_id
        end,

        matches_all(@attributes[:canceled_at] || @attributes[:cancelled_at], event.subscription) do |a, e|
          a == e.canceled_at
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :SUBSCRIPTION_CREATE events.
  class SubscriptionCreateEventHandler < SubscriptionEventHandler; end

  # Event handler for :SUBSCRIPTION_UPDATE events.
  class SubscriptionUpdateEventHandler < SubscriptionEventHandler; end

  # Event handler for :SUBSCRIPTION_DELETE events.
  class SubscriptionDeleteEventHandler < SubscriptionEventHandler; end
end
