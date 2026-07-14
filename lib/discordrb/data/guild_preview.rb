# frozen_string_literal: true

module Discordrb
  # Publicly accessible information about a discoverable guild.
  class GuildPreview
    include Snowflake
    include GuildAttributes

    # @return [String, nil] the ID of the guild's invite splash screen.
    # @see #splash_url
    attr_reader :splash

    # @return [String, nil] the ID of the guild's discovery splash screen.
    # @see #discovery_splash_url
    attr_reader :discovery_splash

    # @return [Array<Emoji>] an array of all of the emojis available on the guild.
    attr_reader :emojis

    # @return [Array<Sticker>] an array of all of the stickers available on the guild.
    attr_reader :stickers

    # @return [Array<Symbol>] the features of the guild, e.g. `:BANNER` or `:VERIFIED`.
    attr_reader :features

    # @return [Integer] the approximate number of members on the guild, offline or not.
    attr_reader :member_count

    # @return [Integer] the approximate number of members that aren't offline on the guild.
    attr_reader :presence_count

    # @return [String, nil] the description of the guild that's shown in the discovery tab.
    attr_reader :description

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @name = data[:name]
      @icon_id = data[:icon]
      @splash = data[:splash]
      @description = data[:description]
      @features = data[:features].map(&:to_sym)
      @discovery_splash = data[:discovery_splash]
      @member_count = data[:approximate_member_count]
      @presence_count = data[:approximate_presence_count]
      @emojis = data[:emojis].map { |emoji| Emoji.new(emoji, @bot) }
      @stickers = data[:stickers].map { |sticker| Sticker.new(sticker, nil, @bot) }
    end

    # Get the guild associated with the guild preview.
    # @return [Guild, nil] The guild associated with the guild preview, or `nil` if the bot is not a member of the guild.
    def guild
      @bot.guild(@id)
    end

    # Utility method to get a guild preview's splash URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] the URL to the guild's splash image, or `nil` if the guild doesn't have a splash image.
    def splash_url(format: 'webp', size: nil)
      Assets[:guild_splash, @id, @splash, format, size:] if @splash
    end

    # Utility method to get a guild preview's discovery splash URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] the URL to the guild's discovery splash image, or `nil` if the guild doesn't have a discovery splash image.
    def discovery_splash_url(format: 'webp', size: nil)
      Assets[:guild_discovery_splash, @id, @discovery_splash, format, size:] if @discovery_splash
    end
  end
end
