# frozen_string_literal: true

module Discordrb
  # The vanity invite for a guild.
  class VanityInvite
    # @return [Integer] the type of the invite.
    attr_reader :type

    # @return [String] the custom code of the vanity invite.
    attr_reader :code

    # @return [Guild] the guild that the vanity invite belongs to.
    attr_reader :guild

    # @return [Channel] the channel that members are popped into when joining.
    attr_reader :channel

    # @return [Integer, nil] the amount of times that the invite has been used.
    attr_reader :usage_count

    # @return [Integer] the approximate number of members on the invite's guild.
    attr_reader :member_count

    # @return [Integer] the approximate number of online members on the invite's guild.
    attr_reader :presence_count

    alias_method :to_s, :code
    alias_method :uses, :usage_count

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @type = data[:type]
      @code = data[:code]
      @usage_count = data[:uses]
      @channel = bot.channel(data[:channel][:id])
      @member_count = data[:approximate_member_count]
      @presence_count = data[:approximate_presence_count]
    end

    # Get an invite URL to the guild using the vanity invite code.
    # @return [String] An invite URL to the guild using it's vanity invite code.
    def link
      "https://discord.gg/#{@code}"
    end

    # Check if the vanity invite is equivalent to another invite.
    # @param other [VanityInvite, Invite] The invite to compare against.
    # @return [true, false] Whether or not the two invites are equivalent.
    def ==(other)
      return false unless other.is_a?(VanityInvite) || other.is_a?(Invite)

      (@code == other.code) && Discordrb.id_compare?(@guild.id, other.guild.id)
    end

    alias_method :eql?, :==
    alias_method :url, :link

    # @!visibility private
    def inspect
      "<VanityInvite code=#{@code} type=#{@type} usage_count=#{@usage_count.inspect}>"
    end
  end
end
