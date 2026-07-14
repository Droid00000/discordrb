# frozen_string_literal: true

module Discordrb
  # A guild tag that a user has chosen to display on their profile.
  class PrimaryGuild
    # @return [Integer] the ID of the guild the primary guild is for.
    attr_reader :guild_id

    # @return [String] the 1-4 character text of the primary guild's tag.
    attr_reader :text

    # @return [String] the hash of the guild tag's badge. Can be used to generate a badge URL.
    # @see #badge_url
    attr_reader :badge

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild_id = data[:identity_guild_id]&.to_i
      @text = data[:tag]
      @badge = data[:badge]
    end

    # Get the guild associated with the primary guild.
    # @return [Guild, nil] The guild associated with the primary guild, or `nil` if the bot is not a member of the guild.
    def guild
      @bot.guild(@guild_id)
    end

    # Get the guild preview associated with this primary guild.
    # @return [GuildPreview, nil] The guild preview associated with the primary guild, or `nil` if it can't be accessed.
    def guild_preview
      @bot.guild_preview(@guild_id)
    end

    # Utility method to get a guild tag's badge URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String] The URL to the guild tag's badge image.
    def badge_url(format: 'webp', size: nil)
      Assets[:guild_tag_badge, @guild_id, @badge, format, size:] if @badge
    end

    # Comparison based off of guild ID.
    # @param other [PrimaryGuild] The object to compare this one against.
    # @return [true, false] Whether the other object is equal to this primary guild.
    def ==(other)
      return false unless other.is_a?(PrimaryGuild)

      Discordrb.id_compare?(other.guild_id, @guild_id)
    end

    alias_method :eql?, :==

    # @!visibility private
    def inspect
      "<PrimaryGuild guild_id=#{@guild_id} text=\"#{@text}\">"
    end
  end
end
