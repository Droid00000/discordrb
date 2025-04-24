# frozen_string_literal: true

module Discordrb::Events
  # Base class for subscription events.
  class SubscriptionEvent < Event
    # @return [Subscription] The subscription for this event.
    attr_reader :subscription

    # @!visibility private
    attr_reader :user_id

    # @!attribute [r] id
    #   @return [Integer]
    #   @see Subscription#id
    # @!attribute [r] status
    #   @return [Integer]
    #   @see Subscription#status
    # @!attribute [r] country
    #   @return [Symbol]
    #   @see Subscription#country
    # @!attribute [r] end_period
    #   @return [Time]
    #   @see Subscription#end_period
    # @!attribute [r] start_period
    #   @return [Time]
    #   @see Subscription#start_period
    # @!attribute [r] canceled_at
    #   @return [Time]
    #   @see Subscription#canceled_at
    # @!attribute [r] user
    #   @return [User]
    #   @see Subscription#user
    # @!attribute [r] sku_ids
    #   @return [Array<Integer>]
    #   @see Subscription#sku_ids
    # @!attribute [r] entitlement_ids
    #   @return [Array<Integer>]
    #   @see Subscription#entitlement_ids
    # @!attribute [r] renewal_sku_ids
    #   @return [Array<Integer>]
    #   @see Subscription#renewal_sku_ids
    delegate :id, :status, :country, :end_period, :start_period, :canceled_at,
             :user, :sku_ids, :entitlement_ids, :renewal_sku_ids, to: :subscription

    # @!visibility hidden
    def initalize(data, bot)
      @bot = bot
      @user_id = data['user_id']&.to_i
      @subscription = Subscription.new(data, bot)
    end
  end

  # Generic superclass for event handlers pertaining to subscriptions.
  class SubscriptionEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(SubscriptionEvent)

      [
        matches_all(@attributes[:skus], event.sku_ids) do |a, e|
          case a
          when Array
            a.map(&:resolve_id) == e
          else
            e.any?(a.resolve_id)
          end
        end,
        matches_all(@attributes[:entitlements], event.entitlement_ids) do |a, e|
          case a
          when Array
            a.map(&:resolve_id) == e
          else
            e.any?(a.resolve_id)
          end
        end,
        matches_all(@attributes[:renewal_skus], event.renewal_sku_ids) do |a, e|
          case a
          when Array
            a.map(&:resolve_id) == e
          else
            e.any?(a.resolve_id)
          end
        end,
        matches_all(@attributes[:status], event.status) do |a, e|
          case a
          when Symbol
            Subscription::STATUS_TYPES[a] == e
          when Integer
            a == e.status
          end
        end,
        matches_all(@attributes[:end_period], event.end_period) { |a, e| a == e },
        matches_all(@attributes[:country], event.country) { |a, e| a.to_sym == e },
        matches_all(@attributes[:user], event.user_id) { |a, e| a.resolve_id == e },
        matches_all(@attributes[:canceled_at], event.canceled_at) { |a, e| a == e },
        matches_all(@attributes[:start_period], event.start_period) { |a, e| a == e },
        matches_all(@attributes[:subscription], event.subscription) { |a, e| a.resolve_id == e.id }
      ].reduce(&:&)
    end
  end

  # Raised whenever a subscription is created.
  class SubscriptionCreateEvent < SubscriptionEvent; end

  # Raised whenever a subscription is updated.
  class SubscriptionUpdateEvent < SubscriptionEvent; end

  # Raised whenever a subscription is deleted.
  class SubscriptionDeleteEvent < SubscriptionEvent; end

  # Event handler for SubscriptionCreateEvent.
  class SubscriptionCreateEventHandler < SubscriptionEventHandler; end

  # Event handler for SubscriptionUpdateEvent.
  class SubscriptionUpdateEventHandler < SubscriptionEventHandler; end

  # Event handler for SubscriptionDeleteEvent.
  class SubscriptionDeleteEventHandler < SubscriptionEventHandler; end
end
