# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Base class for entitlement events.
  class EntitlementEvent < Event
    # @return [Entitlement]
    attr_reader :entitlement

    # @!visibility private
    attr_reader :server_id

    # @!visibility private
    attr_reader :user_id

    # @!visibility private
    def initalize(data, bot)
      @bot = bot
      @user_id = data['user_id']&.to_i
      @server_id = data['guild_id']&.to_i
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
