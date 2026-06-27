# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Generic superclass for entitlements.
  class EntitlementEvent < Event
    # @return [Entitlement] the entitlement associated with the event.
    attr_reader :entitlement

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @entitlement = Discordrb::Entitlement.new(data, @bot)
    end
  end

  # Raised whenever an entitlement is created.
  class EntitlementCreateEvent < EntitlementEvent; end

  # Raised whenever an entitlement is updated.
  class EntitlementUpdateEvent < EntitlementEvent; end

  # Raised whenever an entitlement is deleted.
  class EntitlementDeleteEvent < EntitlementEvent; end

  # Generic event handler for entitlements.
  class EntitlementEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(EntitlementEvent)

      [
        matches_all(@attributes[:id], event.entitlement) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:type], event.entitlement) do |a, e|
          case a
          when Symbol, String
            Discordrb::Entitlement::TYPES[a.to_sym] == e.type
          else
            a == e.type
          end
        end,

        matches_all(@attributes[:ended], event.entitlement) do |a, e|
          case a
          when TrueClass
            e.ended? == true
          when FalseClass
            e.ended? == false
          end
        end,

        matches_all(@attributes[:deleted], event.entitlement) do |a, e|
          case a
          when TrueClass
            e.deleted? == true
          when FalseClass
            e.deleted? == false
          end
        end,

        matches_all(@attributes[:consumed], event.entitlement) do |a, e|
          case a
          when TrueClass
            e.consumed? == true
          when FalseClass
            e.consumed? == false
          end
        end,

        matches_all(@attributes[:end_time], event.entitlement) do |a, e|
          a == e.end_time
        end,

        matches_all(@attributes[:start_time], event.entitlement) do |a, e|
          a == e.start_time
        end,

        matches_all(@attributes[:sku_id] || @attributes[:sku], event.entitlement) do |a, e|
          a&.resolve_id == e.sku_id
        end,

        matches_all(@attributes[:user] || @attributes[:user_id], event.entitlement) do |a, e|
          a&.resolve_id == e&.user_id
        end,

        matches_all(@attributes[:server] || @attributes[:server_id], event.entitlement) do |a, e|
          a&.resolve_id == e&.server_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :ENTITLEMENT_CREATE events.
  class EntitlementCreateEventHandler < EntitlementEventHandler; end

  # Event handler for :ENTITLEMENT_UPDATE events.
  class EntitlementUpdateEventHandler < EntitlementEventHandler; end

  # Event handler for :ENTITLEMENT_DELETE events.
  class EntitlementDeleteEventHandler < EntitlementEventHandler; end
end
