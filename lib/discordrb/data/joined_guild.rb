# frozen_string_literal: true

module Discordrb
  # Minimal information about a guild that the bot has joined.
  class JoinedGuild
    include Snowflake
    include GuildAttributes

    # @return [String, nil] the CDN hash for guild's custom banner.
    attr_reader :banner

    # @return [Array<Symbol>] the features of the guild, e.g. `:VERIFIED`.
    attr_reader :features

    # @return [Permissions] the permissions that the bot has in the guild.
    attr_reader :permissions

    # @return [Integer] the approximate number of total members in the guild.
    attr_reader :member_count

    # @return [Integer] the approximate number of non-offline members in the guild.
    attr_reader :presence_count

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @name = data[:name]
      @icon = data[:icon]
      @banner = data[:banner]
      @features = data[:features]&.map(&:to_sym) || []
      @member_count = data[:approximate_member_count]
      @presence_count = data[:approximate_presence_count]
      @permissions = Permissions.new(data[:permissions].to_i) if data[:permissions]
    end

    # Make the current bot leave the guild. Use this with caution.
    # @return [nil]
    def leave
      @bot.http.leave_guild(@id)
    end

    # Utility method to get a guild's banner URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the guild's banner image, or `nil` if the guild doesn't have a banner image.
    def banner_url(format: 'webp', size: nil)
      Assets[:guild_banner, @id, @banner, format, size:] if @banner
    end

    # @!visibility private
    def inspect
      "<JoinedGuild id=#{@id} name=\"#{@name}\">"
    end
  end
end
