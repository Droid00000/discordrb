# frozen_string_literal: true

module Discordrb
  # An invite to a guild or relationship.
  class Invite
    # @return [Integer] the type of the invite.
    attr_reader :type

    # @return [String] the unique code of the invite.
    attr_reader :code

    # @return [Integer] the flags for the invite combined as a bitfield.
    attr_reader :flags

    # @return [Array<Role, Invite::Role>] the roles granted upon accepting the invite.
    attr_reader :roles

    # @return [Invite::Guild, Discordrb::Guild, nil] the guild the invite is for, if any.
    attr_reader :guild

    # @return [User, nil] the user who was responsible for creating the invite.
    attr_reader :creator

    # @return [Invite::Channel, Discordrb::Channel, nil] the channel the invite is for.
    attr_reader :channel

    # @return [Integer, nil] the duration (in seconds) after which the invite will expire.
    attr_reader :duration

    # @return [Integer, nil] the number of times the invite can be used before it expires.
    attr_reader :max_uses

    # @return [true, false, nil] whether or not the invite will only grant temporary membership.
    attr_reader :temporary
    alias temporary? temporary

    # @return [User, nil] the user's whose "Go Live" stream is shown on the invite's cover.
    attr_reader :stream_user

    # @return [Time, nil] the time at when the invite will expire.
    attr_reader :expiry_time

    # @return [Integer, nil] the number of times that the invite has been used to join the guild.
    attr_reader :usage_count

    # @return [Time, nil] the time at when the invite was created.
    attr_reader :creation_time

    # @return [Liveliness, nil] the activity metrics of the server for the last 7 days, if any.
    attr_reader :activity_metrics

    # @return [Application, nil] the the embedded application to open the voice channel's invite.
    attr_reader :embedded_application

    # @!visibility private
    def initialize(data, resolve, bot)
      @bot = bot
      @type = data[:type]
      @code = data[:code]
      @flags = data[:flags] || 0
      @duration = data[:max_age]
      @max_uses = data[:max_uses]
      @temporary = data[:temporary]
      @creator = @bot.ensure_user(data[:inviter]) if data[:inviter]
      @expiry_time = Time.iso8601(data[:expires_at]) if data[:expires_at]
      @usage_count = data[:uses]
      @creation_time = Time.iso8601(data[:created_at]) if data[:created_at]
      @stream_user = @bot.ensure_user(data[:target_user]) if data[:target_user]
      application = data[:target_application]
      @embedded_application = Application.new(application, @bot) if application
      @activity_metrics = Liveliness.new(data[:liveliness], @bot) if data[:liveliness]

      if data[:channel_id] && resolve
        @channel = @bot.channel(data[:channel_id])
      elsif (channel = data[:channel])
        resolved = @bot.channel(channel[:id].to_i) if resolve
        @channel = resolved || Channel.new(channel, @bot)
      end

      if data[:guild_id] && resolve
        @guild = @bot.guild(data[:guild_id])
      elsif (guild = data[:guild])
        resolved = @bot.guilds[guild[:id].to_i] if @bot.gateway.connected?

        @guild = resolved || Guild.new(guild, data, @bot)
      end

      @roles = if (role_ids = data[:role_ids])
                 role_ids.filter_map { |item| @guild&.role(item.to_i) }
               elsif @guild.is_a?(Discordrb::Invite::Guild)
                 data[:roles]&.map { |item| Role.new(item, @bot) } || []
               elsif @guild.is_a?(Discordrb::Guild)
                 data[:roles]&.filter_map { |item| @guild&.role(item[:id].to_i) } || []
               else
                 []
               end
    end

    # Delete the invite. This cannot be undone.
    # @param reason [String, nil] The audit log reason for deleting the invite.
    # @return [nil]
    def delete(reason: nil)
      @bot.http.delete_invite(@code, reason:)
      nil
    end

    # @!visibility private
    def inspect
      "<Invite type=#{@type} code=\"#{@code}\" creator_id=#{@creator&.id || 'nil'}>"
    end

    # A partial guild for an invite.
    class Guild
      include Snowflake
      include GuildAttributes

      # @return [String, nil] the CDN hash of the guild's splash image.
      attr_reader :splash

      # @return [String, nil] the CDN hash of the guild's banner image.
      attr_reader :banner

      # @return [Array<Symbol>] the features for the guild, e.g. `:VERIFIED`.
      attr_reader :features

      # @return [String, nil] the description that has been set for the guild.
      attr_reader :description

      # @return [Integer, nil] the total amount of users that are in the guild.
      attr_reader :member_count

      # @return [Integer] the amount of times that the guild has been "boosted".
      attr_reader :premium_count

      # @return [Integer, nil] the amount of non-offline users within the guild.
      attr_reader :presence_count

      # @return [String, nil] the code for the guild's custom vanity invite link.
      attr_reader :vanity_invite_code

      # @!visibility private
      def initialize(data, invite, bot)
        @bot = bot
        @id = data[:id].to_i
        @name = data[:name]
        @icon = data[:icon]
        @splash = data[:splash]
        @banner = data[:banner]
        @features = data[:features]&.map(&:to_sym) || []
        @nsfw_level = data[:nsfw_level]
        @description = data[:description]
        @premium_count = data[:premium_subscription_count]
        @vanity_invite_code = data[:vanity_url_code]
        @verification_level = data[:verification_level]
        @member_count = invite[:approximate_member_count]
        @presence_count = invite[:approximate_presence_count]
      end

      # Get the discoverable preview of the guild.
      # @return [GuildPreview, nil] The discoverable preview.
      def guild_preview
        @bot.guild_preview(@id)
      end

      # Get the NSFW level for the guild.
      # @return [Symbol] The NSFW level for the guild.
      # @see Discordrb::Guild::NSFW_LEVELS
      def nsfw_level
        Discordrb::Guild::NSFW_LEVELS.key(@nsfw_level)
      end

      # Get the verification level for the guild.
      # @return [Symbol] The verification level for the guild.
      # @see Discordrb::Guild::VERIFICATION_LEVELS
      def verification_level
        Discordrb::Guild::VERIFICATION_LEVELS.key(@verification_level)
      end

      # Get an invite URL to the guild using the {#vanity_invite_code vanity invite code}.
      # @return [String, nil] An invite link to the guild made using the vanity invite code.
      def vanity_invite_link
        "https://discord.gg/#{@vanity_invite_code}" if @vanity_invite_code
      end

      alias_method :vanity_invite_url, :vanity_invite_link

      # Utility method to get a guild's splash URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
      # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
      # @return [String, nil] The URL to the guild's splash image, or `nil` if the guild doesn't have a splash image.
      def splash_url(format: 'webp', size: nil)
        Assets[:guild_splash, @id, @splash, format, size:] if @splash
      end

      # Utility method to get a guild's banner URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
      # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
      # @return [String, nil] The URL to the guild's banner image, or `nil` if the guild doesn't have a banner image.
      def banner_url(format: 'webp', size: nil)
        Assets[:guild_banner, @id, @banner, format, size:] if @banner
      end
    end

    # A partial channel for an invite.
    class Channel
      include Snowflake

      # @return [String] the name of the channel.
      attr_reader :name

      # @return [Integer] the type of the channel.
      attr_reader :type

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data[:id].to_i
        @name = data[:name]
        @type = data[:type]
      end

      # @!visibility private
      def private?
        dm? || group_dm?
      end

      # @!visibility private
      def thread?
        announcement_thread? || public_thread? || private_thread?
      end

      # @!method text?
      #   @return [true, false] whether or not the channel is a text channel within a guild.
      # @!method voice?
      #   @return [true, false] whether or not the channel is a voice channel within a guild.
      # @!method announcement?
      #   @return [true, false] whether or not the channel is a news channel, allowing members to follow it.
      # @!method stage?
      #   @return [true, false] whether or not the channel is a voice channel used for hosting events within a guild.
      # @!method directory?
      #   @return [true, false] whether or not the channel is the main channel in a student hub.
      # @!method forum?
      #   @return [true, false] whether or not the channel is a thread-only channel within a guild.
      # @!method media?
      #   @return [true, false] whether or not the channel is a thread-only channel that only supports gallery view.
      Discordrb::Channel::TYPES.each do |name, value|
        define_method(:"#{name}?") { @type == value }
      end
    end

    # A partial role for an invite.
    class Role
      include Snowflake

      # @return [String] the name of the role.
      attr_reader :name

      # @return [String, nil] the CDN hash for the role's custom icon.
      attr_reader :icon

      # @return [ColourRGB] the primary color of the role.
      attr_reader :color

      # @return [Integer] the sorting position of the role. Not always unique.
      attr_reader :position

      # @return [String, nil] the unicode emoji for the role's icon.
      attr_reader :unicode_emoji

      # @return [ColourRGB, nil] the third color for the role's gradident.
      attr_reader :tertiary_color

      # @return [ColourRGB, nil] the second color for the role's gradident.
      attr_reader :secondary_color

      alias_method :colour, :color
      alias_method :tertiary_colour, :tertiary_color
      alias_method :secondary_colour, :secondary_color

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data[:id].to_i
        @name = data[:name]
        @icon = data[:icon]
        @position = data[:position]
        @unicode_emoji = data[:unicode_emoji]
        colors = data[:colors]
        @color = ColourRGB.new(colors[:primary_color])
        @tertiary_color = colors[:tertiary_color] ? ColourRGB.new(colors[:tertiary_color]) : nil
        @secondary_color = colors[:secondary_color] ? ColourRGB.new(colors[:secondary_color]) : nil
      end

      # Get a string that will mention the role.
      # @return [String] A string that will mention the role.
      def mention
        "<@&#{@id}>"
      end

      # Get the icon that the role will display in the client.
      # @return [String, nil] The icon URL, the unicode emoji, or nil if the role doesn't have an icon.
      # @note A role can have a unicode emoji, and an icon, but only the icon will be displayed in the UI.
      def display_icon
        icon_url || unicode_emoji
      end

      # Utility method to get a role's custom icon URL.
      # @param format [String] The extension to return the URL in. Can be one of `webp`, `jpg`, or `png`.
      # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
      # @return [String, nil] The URL to the role's icon, or `nil` if the role doesn't have a custom icon set.
      def icon_url(format: 'webp', size: nil)
        Assets[:role_icon, @id, @icon, format, size:] if @icon
      end
    end

    # The activity metrics for a guild.
    class Liveliness
      # @return [Array<Day>] a 7-element array
      #   representing the activity for each day in the week.
      attr_reader :days

      # @return [Time, nil] the time at when the
      #   activity metrics were last re-calculated, or `nil`.
      attr_reader :updated_at

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @updated_at = Time.iso8601(data[:last_updated_ts]) if data[:last_updated_ts]
        @days = data[:msg_activity_bins]&.each_slice(24)&.map { |day| Day.new(day, @bot) } || []
      end

      # @!visibility private
      def inspect
        "<Liveliness updated_at=\"#{@updated_at || 'nil'}\">"
      end

      # The activity metrics for a single day.
      class Day
        # @return [Hash<Integer => Integer>] a hash mapping
        #   the hour in the day, to the activity score for the hour.
        attr_reader :hours

        # @!visibility private
        def initialize(day, bot)
          @bot = bot
          @hours = day.each.with_index(1).to_h { |hour, index| [index, hour] }
        end
      end
    end
  end
end
