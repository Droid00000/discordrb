# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for join requests.
  class GuildJoinRequestEvent < Event
    # @return [Guild] the guild that the join request is for.
    attr_reader :guild

    # @return [Integer] the ID of the user the join request is for.
    attr_reader :user_id

    # @return [JoinRequest] the join request associated with the event.
    attr_reader :join_request

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data[:user_id]&.to_i
      @guild = bot.guild(data[:guild_id].to_i)
      @join_request = Discordrb::JoinRequest.new(data[:request], @guild, @bot)
    end
  end

  # Raised whenever a join request is created.
  class GuildJoinRequestCreateEvent < GuildJoinRequestEvent; end

  # Raised whenever a join request is updated.
  class GuildJoinRequestUpdateEvent < GuildJoinRequestEvent; end

  # Raised whenever a join request is deleted.
  class GuildJoinRequestDeleteEvent < Event
    # @return [Guild] the guild that the join request was for.
    attr_reader :guild

    # @return [Integer] the ID of the user the join request was for.
    attr_reader :user_id

    # @return [Integer] the ID of the join request that was deleted.
    attr_reader :join_request_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data[:user_id]&.to_i
      @join_request_id = data[:id]&.to_i
      @guild = bot.guild(data[:guild_id].to_i)
    end

    # Get the user that the join request was for.
    # @return [User] the user that the join request was for.
    def user
      @user ||= @bot.user(@user_id) if @user_id
    end
  end

  # Generic event handler for guild join request events.
  class GuildJoinRequestEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildJoinRequestEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:id], event.join_request) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:status], event.join_request) do |a, e|
          a&.downcase&.to_sym == e&.status
        end,

        matches_all(@attributes[:reviewed_by], event.join_request) do |a, e|
          a&.resolve_id == e&.reviewed_by&.resolve_id
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for GUILD_JOIN_REQUEST_CREATE events.
  class GuildJoinRequestCreateEventHandler < GuildJoinRequestEventHandler; end

  # Event handler for GUILD_JOIN_REQUEST_UPDATE events.
  class GuildJoinRequestUpdateEventHandler < GuildJoinRequestEventHandler; end

  # Event handler for GUILD_JOIN_REQUEST_DELETE events.
  class GuildJoinRequestDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildJoinRequestDeleteEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:id], event.join_request_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
