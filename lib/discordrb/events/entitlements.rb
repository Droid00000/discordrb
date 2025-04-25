# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Base class for entitlement events.
  class EntitlementEvent < Event
    # @return [Entitlement]
    attr_reader :entitlement

    # @!attribute [r] id
    #   @return [Integer]
    #   @see entitlement#id
    # @!attribute [r] sku_id
    #   @return [Integer]
    #   @see entitlement#sku_id
    # @!attribute [r] application_id
    #   @return [Integer]
    #   @see entitlement#application_id
    # @!attribute [r] type
    #   @return [Integer]
    #   @see entitlement#type
    # @!attribute [r] deleted?
    #   @return [true, false]
    #   @see entitlement#deleted?
    # @!attribute [r] starts_at
    #   @return [Time]
    #   @see entitlement#starts_at
    # @!attribute [r] ends_at
    #   @return [Time]
    #   @see entitlement#ends_at
    # @!attribute [r] consumed?
    #   @return [true, false]
    #   @see entitlement#consumed?
    # @!attribute [r] user?
    #   @return [true, false]
    #   @see entitlement#user?
    # @!attribute [r] server?
    #   @return [true, false]
    #   @see entitlement#server?
    # @!attribute [r] user
    #   @return [User]
    #   @see entitlement#user
    # @!attribute [r] server
    #   @return [Server]
    #   @see entitlement#server
    # @!attribute [r] consume
    #   @return [true]
    #   @see entitlement#consume
    # @!attribute [r] sku
    #   @return [SKU]
    #   @see entitlement#sku
    delegate :id, :sku_id, :application_id, :type, :deleted?, :starts_at, :ends_at,
             :consumed?, :user?, :server?, :user, :server, :consume, :sku, to: :entitlement

    # @!visibility private
    def initalize(data, bot)
      @bot = bot
      @entitlement = Entitlement.new(data, bot)
    end
  end

  # Raised whenever an entitlement is created.
  class EntitlementCreateEvent < EntitlementEvent; end

  # Raised whenever an entitlement is updated.
  class EntitlementUpdateEvent < EntitlementEvent; end

  # Raised whenever an entitlement is deleted.
  class EntitlementDeleteEvent < EntitlementEvent; end
end
