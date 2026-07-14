# frozen_string_literal: true

module Discordrb::Events
  # Common superclass for all lifetime events
  class LifetimeEvent < Event
    # @!visibility private
    def initialize(bot)
      @bot = bot
    end
  end

  # @see Discordrb::EventContainer#ready
  class ReadyEvent < LifetimeEvent; end

  # Event handler for {ReadyEvent}
  class ReadyEventHandler < TrueEventHandler; end

  # @see Discordrb::EventContainer#disconnected
  class DisconnectEvent < LifetimeEvent; end

  # Event handler for {DisconnectEvent}
  class DisconnectEventHandler < TrueEventHandler; end

  # @see Discordrb::EventContainer#resumed
  class ResumedEvent < LifetimeEvent; end

  # Event handler for {ResumedEvent}
  class ResumedEventHandler < TrueEventHandler; end
end
