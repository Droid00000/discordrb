# frozen_string_literal: true

module Discordrb
  # Information about how a member joined a guild.
  class SupplementalMember
    # Mapping of join methods.
    JOIN_TYPES = {
      unknown: 0,
      bot: 1,
      integration: 2,
      discovery: 3,
      student_hub: 4,
      invite: 5,
      vanity_invite: 6,
      manual_verification: 7,
      social_layer_linked_channel: 8
    }.freeze

    # @return [Guild] the guild that the supplemental member is for.
    attr_reader :guild

    # @return [Member] the member that the supplemental member represents.
    attr_reader :member

    # @return [Integer, nil] the method that the member used to join the guild.
    attr_reader :join_type

    # @return [Integer, nil] the {Invite#creator creator} of the invite associated
    #   with the {#invite_code}, or the {Integration integration} that added the member.
    attr_reader :inviter_id

    # @return [String, nil] the invite code that the member used to join the guild.
    attr_reader :invite_code

    # @return [Symbol, nil] the type of integration that added the member to the guild.
    attr_reader :integration_type

    # @return [Integer, nil] the ID of the channel that's linked to the lobby used to join the guild.
    attr_reader :lobby_channel_id

    # @return [Integer, nil] the ID of the application that owns the linked lobby used to join the guild.
    attr_reader :lobby_application_id

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @member = guild.ensure_member(data[:member])
      @join_type = data[:join_source_type]
      @inviter_id = data[:inviter_id]&.to_i
      @invite_code = data[:source_invite_code]
      @integration_type = data[:integration_type]&.to_sym
      @lobby_channel_id = data[:join_source_channel_id]&.to_i
      @lobby_application_id = data[:join_source_application_id]&.to_i
    end

    # Check if two supplemental members are equivalent.
    # @param other [Object] The object to compare against for equality.
    # @return [true, false] Whether or not the two objects are equivalent.
    def ==(other)
      return false unless other.is_a?(SupplementalMember)

      @guild.id == other.guild.id && @member == other.member
    end

    alias :eql? :==

    #  ######## ##    ## ######## ########  ######
    #     ##     ##  ##  ##     ## ##      ##    ##
    #     ##      ####   ##     ## ##      ##
    #     ##       ##    ########  ######   ######
    #     ##       ##    ##        ##            ##
    #     ##       ##    ##        ##       ##   ##
    #     ##       ##    ##        ########  ######

    # @!group Join Types

    # @!method unknown?
    #   @return [true, false] whether the member joined the guild through an unknown source.
    # @!method bot?
    #   @return [true, false] whether the member was added to the guild by a bot using the `guilds.join` scope.
    # @!method integration?
    #   @return [true, false] whether the member was added to the guild by an integration (e.g. Twitch).
    # @!method discovery?
    #   @return [true, false] whether the member joined the guild through guild discovery.
    # @!method student_hub?
    #   @return [true, false] whether the member joined the guild through a student hub.
    # @!method invite?
    #   @return [true, false] whether the member joined the guild through a standard invite.
    # @!method vanity_invite?
    #   @return [true, false] whether the member joined the guild through the guild's vanity invite.
    # @!method manual_verification?
    #   @return [true, false] whether the member was accepted into the guild after applying for membership.
    # @!method social_layer_linked_channel?
    #   @return [true, false] whether the member joined the guild through a linked lobby.
    JOIN_TYPES.each do |name, value|
      define_method("#{name}?") { @join_type == value }
    end

    # @!endgroup

    # Get the user who invited the member to the guild.
    # @return [User, nil] The user who invited the member to the guild.
    def inviter
      (@inviter ||= @bot.user(@inviter_id)) if @inviter_id
    end

    # Get the invite that the member used to join the guild.
    # @return [Invite, nil] The invite that the member used to join the guild.
    def invite
      (@invite ||= @bot.invite(@invite_code)) if @invite_code
    end

    # Get the channel linked to the lobby that the member used to join the guild.
    # @return [Channel, nil] The linked channel that the member used to join the guild.
    def lobby_channel
      (@lobby_channel ||= @bot.channel(@lobby_channel_id)) if @lobby_channel_id
    end
  end
end
