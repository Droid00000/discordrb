# frozen_string_literal: true

module Discordrb
  # Basic attributes a guild should have.
  module GuildAttributes
    # @return [String] the guild's name.
    attr_reader :name

    # @return [String, nil] the hash of the guild's icon, if any.
    attr_reader :icon

    # Utility method to get a guild's icon URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the guild's icon, or `nil` if the guild doesn't have an icon image.
    def icon_url(format: 'webp', size: nil)
      Assets[:guild_icon, @id, @icon, format, size:] if @icon
    end
  end

  # An isolated collection of channels and users on Discord.
  class Guild
    include Snowflake
    include GuildAttributes

    # Mapping of MFA levels.
    MFA_LEVELS = {
      none: 0,
      elevated: 1
    }.freeze

    # Mapping of NSFW levels.
    NSFW_LEVELS = {
      default: 0,
      explicit: 1,
      safe: 2,
      age_restricted: 3
    }.freeze

    # Mapping of verification levels.
    VERIFICATION_LEVELS = {
      none: 0,
      low: 1,
      medium: 2,
      high: 3,
      very_high: 4
    }.freeze

    # Mapping of default notification levels.
    NOTIFICATION_LEVELS = {
      all_messages: 0,
      only_mentions: 1
    }.freeze

    # Mapping of explicit content filter levels.
    FILTER_LEVELS = {
      disabled: 0,
      members_without_roles: 1,
      all_members: 2
    }.freeze

    # Mapping of system channel flags.
    SYSTEM_CHANNEL_FLAGS = {
      join_notifications: 1 << 0,
      boost_notifications: 1 << 1,
      reminder_notifications: 1 << 2,
      join_notification_replies: 1 << 3,
      role_subscription_notifications: 1 << 4,
      role_subscription_notification_replies: 1 << 5
    }.freeze

    # @return [Array<Symbol>] the features of the guild, e.g. `:BANNER`, `:VERIFIED`, etc.
    attr_reader :features

    # @return [Integer] the amount of time after which a voice user gets moved into the AFK channel, in seconds.
    attr_reader :afk_timeout

    # @return [Hash<Integer => VoiceState>] a mapping of user IDs to voice states for each member on the guild.
    attr_reader :voice_states

    # @return [Integer] the amount of times the guild has been boosted.
    attr_reader :premium_count

    # @return [Integer] the guild's Nitro boost level, `0` if no level.
    attr_reader :premium_tier

    # @return [String] the preferred locale of the guild. Used in guild discovery and notices from Discord.
    attr_reader :locale

    # @return [String, nil] the description of the guild. Shown in guild discovery and invites to the guild.
    attr_reader :description

    # @return [String, nil] the hash of the guild's banner image or GIF.
    attr_reader :banner

    # @return [String, nil] the hash of the guild's invite splash image.
    attr_reader :splash

    # @return [Integer] the maximum number of members that can join the guild.
    attr_reader :max_member_count

    # @return [String, nil] the code of the guild's custom vanity invite link.
    attr_reader :vanity_invite_code

    # @return [Integer, nil] the maximum number of members that can concurrently be online in the guild.
    #   Always set to `nil` except for the largest of guilds.
    attr_reader :max_presence_count

    # @return [String, nil] the hash of the guild's discovery splash image.
    attr_reader :discovery_splash

    # @return [Integer] the flags for the guild's system channel. The flags indicate suppression. E.g. if
    #   the `join_notifications` flag is set in the bitfield, then `join_notifications` have been disabled.
    attr_reader :system_channel_flags

    # @return [Integer] the maximum number of members that can concurrently watch a stream in a voice channel.
    attr_reader :max_video_channel_members

    # @return [Integer] the maximum number of members that can concurrently watch a stream in a stage channel.
    attr_reader :max_stage_video_channel_members

    # @return [true, false] whether or not the guild has enabled the boost progress bar.
    attr_reader :premium_progress_bar
    alias_method :premium_progress_bar?, :premium_progress_bar

    # @return [Time, nil] the time at when the last raid was detected on the guild.
    attr_reader :raid_detected_at

    # @return [Time, nil] the time at when DM spam was last detected on the guild.
    attr_reader :dm_spam_detected_at

    # @return [Time, nil] the time at when invites will be re-enabled on the guild.
    attr_reader :invites_disabled_until

    # @return [Time, nil] the time at when non-friend direct messages will be re-enabled on the guild.
    attr_reader :dms_disabled_until

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @members = {}
      @voice_states = {}
      @emojis = {}
      @channels = {}
      @scheduled_events = {}
      @soundboard_sounds = {}
      @automod_rules = {}
      @stickers = {}
      @threads = {}
      @member_chunk_queries = {}

      # Whether the guild's members have been chunked (resolved using op 8 - GUILD_MEMBERS_CHUNK).
      @chunked = false

      update_data(data)
    end

    #  ##     ##    ###    #### ##    ##
    #  ###   ###   ## ##    ##  ###   ##
    #  #### ####  ##   ##   ##  ####  ##
    #  ## ### ## ##     ##  ##  ## ## ##
    #  ##     ## #########  ##  ##  ####
    #  ##     ## ##     ##  ##  ##   ###
    #  ##     ## ##     ## #### ##    ##

    # @!group General

    # Get the discoverable preview for the guild.
    # @return [GuildPreview] The guild's preview.
    def preview
      @bot.fetch_guild_preview(@id)
    end

    # Get the webhooks for the guild.
    # @return [Array<Webhook>] The webhooks for the guild.
    def webhooks
      response = @bot.http.list_guild_webhooks(@id)
      response.map { |webhook| Webhook.new(webhook, @bot) }
    end

    # Get the voice regions for the guild.
    # @return [Array<VoiceRegion>] The voice regions for the guild.
    def voice_regions
      return @voice_regions if @voice_regions

      response = @bot.http.list_guild_voice_regions(@id)
      @voice_regions = response.map { |region| VoiceRegion.new(region) }
    end

    # Get the integrations added to the guild.
    # @return [Array<Integration>] The integrations for the guild.
    # @note If the guild has more than 50 integrations, they cannot be fetched.
    def integrations
      response = @bot.http.list_guild_integrations(@id)
      response.map { |integration| Integration.new(integration, self, @bot) }
    end

    # Get a URL that will navigate to the guild in the Discord client when clicked.
    # @return [String] A link that will navigate to the guild in the Discord client.
    def jump_link
      "https://discord.com/channels/#{@id}"
    end

    # Modify the properties of the guild.
    # @param name [String] The new 2-100 character name of the guild.
    # @param verification_level [Symbol, Integer, nil] The new verification level of the guild.
    # @param notification_level [Symbol, Integer, nil] The new default message notification level of the guild.
    # @param explicit_content_filter [Symbol, Integer, nil] The new explicit content filter level of the guild.
    # @param afk_channel [Channel, Integer, String, nil] The new AFK voice channel members should be automatically moved to.
    # @param afk_timeout [Integer] The new AFK timeout in seconds. Can be set to one of `60`, `300`, `900`, `1800`, or `3600`.
    # @param icon [#read, File, nil] The new icon of the guild. Should be a file-like object that responds to `#read`.
    # @param splash [#read, File, nil] The new invite splash of the guild. Should be a file-like object that responds to `#read`.
    # @param discovery_splash [#read, File, nil] The new discovery splash of the guild. Should be a file-like object that responds to `#read`.
    # @param banner [#read, File, nil] The new banner of the guild. Should be a file-like object that responds to `#read`.
    # @param system_channel [Channel, Integer, String, nil] The new channel where system messages should be sent.
    # @param system_channel_flags [Integer, Symbol, Array<Integer, Symbol>] The new system channel flags to set for the guild's system channel.
    # @param rules_channel [Channel, Integer, String, nil] The new channel where the guild displays its rules or guidelines.
    # @param public_updates_channel [Channel, Integer, String, nil] The new channel where public updates should be sent.
    # @param locale [String, Symbol, nil] The new preferred locale of the guild; primarily for community guilds.
    # @param features [Array<String, Symbol>] The new features to set for the guild.
    # @param description [String, nil] The new description of the guild.
    # @param premium_progress_bar [true, false] Whether or not the boosting progress bar should be visible.
    # @param safety_alerts_channel [Channel, Integer, String, nil] The new channel where safety alerts should be sent.
    # @param widget_enabled [true, false, nil] Whether or not the guild's widget should be enabled.
    # @param widget_channel [Channel, Integer, String, nil] The new invite channel for the guild's widget.
    # @param dms_disabled_until [Time, nil] The time at when non-friend direct messages will be enabled again.
    # @param invites_disabled_until [Time, nil] The time at when invites will no longer be disabled.
    # @param add_features [Array<String, Symbol>, String, Symbol] The features to add to the guild.
    # @param remove_features [Array<String, Symbol>, String, Symbol] The features to remove from the guild.
    # @param reason [String, nil] The reason to show in the guild's audit log for modifying the guild.
    # @return [nil]
    def modify(
      name: :undef, verification_level: :undef, notification_level: :undef, explicit_content_filter: :undef,
      afk_channel: :undef, afk_timeout: :undef, icon: :undef, splash: :undef, discovery_splash: :undef, banner: :undef,
      system_channel: :undef, system_channel_flags: :undef, rules_channel: :undef, public_updates_channel: :undef,
      locale: :undef, features: :undef, description: :undef, premium_progress_bar: :undef, safety_alerts_channel: :undef,
      widget_enabled: :undef, widget_channel: :undef, dms_disabled_until: :undef, invites_disabled_until: :undef,
      add_features: :undef, remove_features: :undef, reason: nil
    )
      data = {
        name: name,
        verification_level: VERIFICATION_LEVELS[verification_level] || verification_level,
        default_message_notifications: NOTIFICATION_LEVELS[notification_level] || notification_level,
        explicit_content_filter: FILTER_LEVELS[explicit_content_filter] || explicit_content_filter,
        afk_channel_id: afk_channel == :undef ? afk_channel : afk_channel&.resolve_id,
        afk_timeout: afk_timeout,
        icon: icon.respond_to?(:read) ? Discordrb.encode64(icon) : icon,
        splash: splash.respond_to?(:read) ? Discordrb.encode64(splash) : splash,
        discovery_splash: discovery_splash.respond_to?(:read) ? Discordrb.encode64(discovery_splash) : discovery_splash,
        banner: banner.respond_to?(:read) ? Discordrb.encode64(banner) : banner,
        system_channel_id: system_channel == :undef ? system_channel : system_channel&.resolve_id,
        system_channel_flags: system_channel_flags == :undef ? system_channel_flags : [*system_channel_flags].reduce(0) { |sum, flag| sum | (SYSTEM_CHANNEL_FLAGS[flag] || flag.to_i) },
        rules_channel_id: rules_channel == :undef ? rules_channel : rules_channel&.resolve_id,
        public_updates_channel_id: public_updates_channel == :undef ? public_updates_channel : public_updates_channel&.resolve_id,
        preferred_locale: locale,
        features: features == :undef ? features : features.map { |feature| feature.to_sym.upcase }.tap(&:uniq!),
        description: description,
        premium_progress_bar_enabled: premium_progress_bar,
        safety_alerts_channel_id: safety_alerts_channel == :undef ? safety_alerts_channel : safety_alerts_channel&.resolve_id
      }

      if add_features != :undef || remove_features != :undef
        raise ArgumentError, "'add_features' and 'remove_features' are mutually exclusive with 'features'" unless features == :undef

        current = @features.to_set

        if remove_features != :undef
          remove_features = [remove_features] unless remove_features.respond_to?(:each)
          remove_features.each { |remove_item| current.delete(remove_item.upcase.to_sym) }
        end

        if add_features != :undef
          add_features = [add_features] unless add_features.respond_to?(:each)
          add_features.each { |appended_value| current.add(appended_value.upcase.to_sym) }
        end

        data[:features] = current
      end

      if widget_enabled != :undef || widget_channel != :undef
        widget_data = {
          enabled: widget_enabled,
          channel_id: widget_channel == :undef ? widget_channel : widget_channel&.resolve_id
        }

        cache_widget(@bot.http.modify_guild_widget_settings(@id, **widget_data, reason: reason))
      end

      if invites_disabled_until != :undef || dms_disabled_until != :undef
        incidents_data = {
          dms_disabled_until: dms_disabled_until == :undef ? @dms_disabled_until&.iso8601 : dms_disabled_until&.iso8601,
          invites_disabled_until: invites_disabled_until == :undef ? @invites_disabled_until&.iso8601 : invites_disabled_until&.iso8601
        }

        if (dms_disabled_until == :undef) && @dms_disabled_until && (@dms_disabled_until <= Time.now)
          incidents_data[:dms_disabled_until] = :undef
        end

        if (invites_disabled_until == :undef) && @invites_disabled_until && (@invites_disabled_until <= Time.now)
          incidents_data[:invites_disabled_until] = :undef
        end

        process_incident_actions(@bot.http.modify_guild_incident_actions(@id, **incidents_data, reason: reason))
      end

      return unless data.any? { |_, value| value != :undef }

      update_data(@bot.http.modify_guild(@id, **data, reason: reason))
      nil
    end

    alias_method :jump_url, :jump_link
    alias_method :available_voice_regions, :voice_regions

    # @!endgroup

    #  ##       ######## ##     ## ######## ##        ######
    #  ##       ##       ##     ## ##       ##       ##    ##
    #  ##       ##       ##     ## ##       ##       ##
    #  ##       ######   ##     ## ######   ##        ######
    #  ##       ##        ##   ##  ##       ##             ##
    #  ##       ##         ## ##   ##       ##       ##    ##
    #  ######## ########    ###    ######## ########  ######

    # @!group Levels

    # Get the MFA level for the guild.
    # @return [Symbol] The MFA level for the guild.
    # @see MFA_LEVELS
    def mfa_level
      MFA_LEVELS.key(@mfa_level)
    end

    # Get the NSFW level for the guild.
    # @return [Symbol] The NSFW level for the guild.
    # @see NSFW_LEVELS
    def nsfw_level
      NSFW_LEVELS.key(@nsfw_level)
    end

    # Get the content filter level for the guild.
    # @return [Symbol] The filter level for the guild.
    # @see FILTER_LEVELS
    def explicit_content_filter
      FILTER_LEVELS.key(@explicit_content_filter)
    end

    # Get the verification level for the guild.
    # @return [Symbol] The verification level for the guild.
    # @see VERIFICATION_LEVELS
    def verification_level
      VERIFICATION_LEVELS.key(@verification_level)
    end

    # Get the default notification level for the guild.
    # @return [Symbol] The default notification level for the guild.
    # @see NOTIFICATION_LEVELS
    def notification_level
      NOTIFICATION_LEVELS.key(@notification_level)
    end

    alias_method :explicit_content_filter_level, :explicit_content_filter

    # @!endgroup

    #     ###     ######   ######  ######## ########  ######
    #    ## ##   ##    ## ##    ## ##          ##    ##    ##
    #   ##   ##  ##       ##       ##          ##    ##
    #  ##     ##  ######   ######  ######      ##     ######
    #  #########       ##       ## ##          ##          ##
    #  ##     ## ##    ## ##    ## ##          ##    ##    ##
    #  ##     ##  ######   ######  ########    ##     ######

    # @!group Assets

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

    # Utility method to get a guild's discovery splash URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the guild's discovery splash image, or `nil` if the guild doesn't have a discovery splash image.
    def discovery_splash_url(format: 'webp', size: nil)
      Assets[:guild_discovery_splash, @id, @discovery_splash, format, size:] if @discovery_splash
    end

    # @!endgroup

    #  ######   #######  ##       ########  ######
    #  ##   ## ##     ## ##       ##       ##
    #  ##   ## ##     ## ##       ##       ##
    #  ######  ##     ## ##       ######    ######
    #  ## ##   ##     ## ##       ##             ##
    #  ##  ##  ##     ## ##       ##             ##
    #  ##   ##  #######  ######## ######## ######

    # @!group Roles

    # Get the default role for the guild.
    # @return [Role] The `@everyone` role for the guild.
    def everyone_role
      @roles[@id]
    end

    # Get the auto-generated role for the current bot.
    # @return [Role, nil] The auto-generated role for the bot, or
    #   `nil` if an auto-generated role does not exist for the bot.
    def bot_role
      roles.find { |role| role.bot_id == bot.user.id }
    end

    # Get the roles for the guild.
    # @param sorted [true, false] Whether to return the roles sorted by
    #   their position in the role hierarchy.
    # @param bypass_cache [true, false] Whether the cached roles should
    #   be ignored and re-fetched via an HTTP request.
    # @return [Array<Role>] The roles for the guild.
    def roles(sorted: false, bypass_cache: false)
      process_roles(@bot.http.list_guild_roles(@id)) if bypass_cache

      sorted ? @roles.values.tap(&:sort!) : @roles.values
    end

    # Get a role from the guild via its ID.
    # @param id [String, Integer] The ID of the role that should be resolved.
    # @param request [true, false] Whether to request the role if it isn't cached.
    # @return [Role, nil] The role identified by its ID, or `nil` if it couldn't be found.
    def role(id, request: false)
      id = id.resolve_id
      cached = @roles[id]
      return cached if cached || !request

      data = @bot.http.get_guild_role(@id, id)
      Role.new(data, self, @bot).tap { |role| cache_role(role) }
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Get a mapping of role IDs to the amount of members who have the role.
    # @example Print out the name of the roles in a guild followed by the role's member count.
    #  guild = bot.guild(81384788765712384)
    #
    #  guild.role_member_counts.each do |id, count|
    #    puts("Name: #{guild.role(id).name}, Count: #{count}")
    #  end
    # @return [Hash<Integer => Integer>] A hash mapping role IDs to their respective member counts.
    def role_member_counts
      response = @bot.http.get_guild_role_member_counts(@id)
      response.transform_keys! { |key| key.name.to_i }
      response.tap { response[@id] = @member_count }
    end

    # Create a new role.
    # @param name [String, nil] The name of the role; between 1-100 characters.
    # @param unicode_emoji [String, nil] The standard unicode emoji to set for the role's icon.
    # @param display_icon [File, String, Emoji, nil] The custom icon or unicode emoji to set for the role.
    # @param permissions [Permissions, Integer, String, nil] The permissions to set for the role.
    # @param icon [File, #read, nil] The custom icon to set for the role. Must be a file-like object.
    # @param hoisted [true, false, nil] Whether or not the role should be shown separately in the member's list.
    # @param mentionable [true, false, nil] Whether or not any guild member can mention the role in messages.
    # @param colour [Integer, ColourRGB, nil] The primary colour to set for the role.
    # @param tertiary_colour [Integer, ColourRGB, nil] The tertiary colour to set for the role.
    # @param secondary_colour [Integer, ColourRGB, nil] The secondary colour to set for the role.
    # @param reason [String, nil] the reason to show in the guild's audit log for creating the role.
    # @yieldparam builder [Permissions] An optional permissions builder. Ignored when `permissions:` is passed.
    # @note The American spelling can be used instead of the British spelling for all of the colour parameters.
    # @return [Role] The newly created role on the guild.
    def create_role(
      name: nil, hoisted: nil, mentionable: nil, icon: nil, unicode_emoji: nil, display_icon: nil,
      colour: nil, color: nil, secondary_colour: nil, secondary_color: nil, tertiary_colour: nil,
      tertiary_color: nil, permissions: nil, reason: nil
    )
      if display_icon
        if icon || unicode_emoji
          raise ArgumentError, "'display_icon' is mutually exclusive with 'icon' and 'unicode_emoji'"
        end

        if display_icon.respond_to?(:read)
          icon = display_icon
          unicode_emoji = :undef
        elsif display_icon.is_a?(String)
          icon = :undef
          unicode_emoji = display_icon
        elsif display_icon.is_a?(Emoji)
          if display_icon.id
            request = Faraday.get(display_icon.url(format: 'png', size: 4096))
            icon = request.success? ? StringIO.new(request.body, 'rb') : :undef
            unicode_emoji = :undef
          elsif display_icon.name
            icon = :undef
            unicode_emoji = display_icon.name
          end
        end
      end

      permissions = if permissions.is_a?(Array)
                      Permissions.bits(permissions)
                    elsif permissions.respond_to?(:bits)
                      permissions.bits
                    else
                      permissions
                    end

      if block_given? && !permissions
        yield((builder = Permissions.new(0)))
        permissions = builder.bits
      end

      data = {
        name: name&.to_s || 'new role',
        permissions: permissions&.to_s || :undef,
        icon: icon.respond_to?(:read) ? Discordrb.encode64(icon) : (icon || :undef),
        unicode_emoji: unicode_emoji || :undef,
        hoist: hoisted.nil? ? :undef : hoisted,
        mentionable: mentionable.nil? ? :undef : mentionable,
        colors: {
          primary_color: (colour || color || 0).to_i,
          tertiary_color: (tertiary_colour || tertiary_color)&.to_i,
          secondary_color: (secondary_colour || secondary_color)&.to_i
        }
      }

      response = @bot.http.create_guild_role(@id, **data, reason:)
      Role.new(response, self, @bot).tap { |role| cache_role(role) }
    end

    # @!endgroup

    #  ##     ## ######## ##     ## ########  ######## ########   ######
    #  ###   ### ##       ###   ### ##     #  ##       ##     ## ##    ##
    #  #### #### ##       #### #### ##     #  ##       ##     ## ##
    #  ## ### ## ######   ## ### ## #######   ######   ########   ######
    #  ##     ## ##       ##     ## ##     #  ##       ##   ##         ##
    #  ##     ## ##       ##     ## ##     #  ##       ##    ##  ##    ##
    #  ##     ## ######## ##     ## ########  ######## ##     ##  ######

    # @!group Members

    # Get the member who owns the guild.
    # @return [Member] The member who owns the guild.
    def owner
      member(@owner_id)
    end

    # Get the bot's own member on the guild.
    # @return [Member] The member for the current bot.
    def bot
      member(@bot.profile)
    end

    # Make the current bot leave the guild. Use this with caution.
    # @return [nil]
    def leave
      @bot.http.leave_guild(@id)
    end

    # Get the bot accounts that are in the guild.
    # @return [Array<Member>] An array of all the bot accounts on the guild.
    def bot_members
      members.select(&:bot_account?)
    end

    # Get the user accounts that are in the guild.
    # @return [Array<Member>] An array of all the user accounts on the guild.
    def non_bot_members
      members.reject(&:bot_account?)
    end

    # Get the presence count of the guild.
    # @return [Integer] The amount of non-offline members in the guild.
    def presence_count
      update_data(@bot.http.get_guild(@id, with_counts: true))
      @presence_count
    end

    # Get the member count of the guild.
    # @param bypass_cache [true, false] Whether the cached member
    #   count should be ignored and re-fetched via an HTTP request.
    # @return [Integer] The amount of members that have joined the guild.
    def member_count(bypass_cache: false)
      return @member_count unless bypass_cache

      update_data(@bot.http.get_guild(@id, with_counts: true))
      @member_count
    end

    # Get a single member in the guild by their user ID.
    # @param user_id [Integer, String, User] The user ID of the member to fetch.
    # @param request [true, false, nil] Whether to fetch the member if it isn't cached.
    # @return [Member, nil] The member for the given user ID, or `nil` if it couldn't be found.
    def member(user_id, request: true)
      id = user_id.resolve_id
      cached = @members[id]
      return cached if cached || !request

      response = @bot.http.get_guild_member(@id, id)
      Member.new(response, self, @bot).tap { |member| cache_member(member) }
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Kick a member from the guild.
    # @param id [User, Member, String, Integer] The member to kick.
    # @param reason [String, nil] The reason to show in the guild's audit log for kicking the member.
    # @return [nil]
    def kick(id, reason: nil)
      @bot.http.remove_guild_member(@id, id.resolve_id, reason:)
      nil
    end

    # Adds a member to the guild that has granted the bot an OAuth2 access token with the `guilds.join` scope.
    #   For more information, see: https://discord.com/developers/docs/topics/oauth2.
    # @param user [User, String, Integer] The user, or the ID of the user to add to the guild.
    # @param access_token [String] The OAuth2 Bearer token that has been granted the `guilds.join` scope.
    # @param nickname [String, nil] The nickname to give the member upon joining.
    # @param roles [Role, Array<Role, String, Integer>] The role (or roles) to give the member upon joining.
    # @param muted [true, false] Whether the member should be guild muted upon joining.
    # @param deafened [true, false] Whether the member should be guild deafened upon joining.
    # @param flags [Integer, nil] The flags to set for the member upon joining.
    # @note Your bot must be present in the guild, and have permission to create instant invites.
    # @return [Member, nil] The member that was added, or `nil` if the user is already a guild member.
    def add_member(user, access_token, nickname: nil, roles: [], deafened: false, muted: false, flags: nil)
      data = {
        mute: muted,
        deaf: deafened,
        nick: nickname || :undef,
        access_token: access_token,
        flags: flags&.to_i || :undef,
        roles: roles ? [*roles].map(&:resolve_id) : :undef
      }

      response = @bot.http.add_guild_member(@id, user.resolve_id, **data)
      response ? cache_member(Member.new(response, self, @bot), increment: @bot.gateway.intents.nobits?(INTENTS[:guild_members])) : nil
    end

    # Get a list of all of the members that are in the guild.
    # @return [Array<Member>] An array of all of the members that are in the guild.
    # @raise [Discordrb::Errors::MissingGatewayIntent] If the bot was started without the `:guild_members` intent.
    def members
      return @members.values if @chunked

      Discordrb::LOGGER.debug("Members for guild #{@id} not chunked yet - initiating")

      # If the GUILD_MEMBERS intent isn't set, the gateway won't respond when we ask for members.
      if @bot.gateway.intents.nobits?(INTENTS[:guild_members])
        raise Discordrb::Errors::MissingGatewayIntent, 'The :guild_members intent is required to get guild members'
      end

      @bot.request_chunks(@id)
      sleep(0.01) until @chunked
      @members.values
    end

    # Query the members in the guild.
    # @param name [String, nil] Get members with matching usernames or nicknames.
    # @param limit [Integer, nil] The maximum number of members to fetch; between 1-1000.
    # @param users [Array, Set, #resolve_id, nil] Get members for these user IDs; between 1-100.
    # @return [QueriedMembers] The resulting guild members for the search query that was executed.
    # @note the `name:` and `users:` parameters are mutually exclusive. At least one must be passed.
    #   `limit:` cannot be used in conjunction with the `users:` parameter.
    def query_members(name: nil, limit: nil, users: nil)
      if name && users
        raise ArgumentError, "'name' and 'users' are mutually exclusive"
      end

      if !name && !users
        raise ArgumentError, "One of 'name' or 'users' must be provided"
      end

      if users && limit
        raise ArgumentError, "'limit' cannot be used in conjunction with 'users'"
      end

      if name && !((limit ||= 100).between?(1, 1000))
        raise ArgumentError, "'limit' must be between 1-1000 when using 'name'"
      end

      if users && !((users = [*users]).length.between?(1, 100))
        raise ArgumentError, "The length of 'users' must be between 1-100 elements"
      end

      if name
        data = @bot.http.search_guild_members(@id, name:, limit:)

        return QueriedMembers.new({ members: data }, self, @bot)
      end

      timeout_at = Time.now + 70
      nonce = SecureRandom.urlsafe_base64(24)
      @member_chunk_queries[nonce] = nil

      presences = @bot.gateway.intents.anybits?(INTENTS[:guild_presences])

      @bot.gateway.request_guild_members(guild: @id, nonce:, users:, presences:)

      sleep(0.01) until (@member_chunk_queries[nonce]) || (Time.now > timeout_at)

      QueriedMembers.new(@member_chunk_queries.delete(nonce) || { timeout: true }, self, @bot)
    end

    alias_method :users, :members
    alias_method :current_bot, :bot
    alias_method :online_users, :online_members

    # @!endgroup

    #  ##     ## ######## ##     ## ######## ######## ########
    #  ###   ### ##       ###   ### ##     ## ##       ##     ##
    #  #### #### ##       #### #### ##     ## ##       ##     ##
    #  ## ### ## ######   ## ### ## ########  ######   ########
    #  ##     ## ##       ##     ## ##     ## ##       ##   ##
    #  ##     ## ##       ##     ## ##     ## ##       ##    ##
    #  ##     ## ######## ##     ## ########  ######## ##     ##
    #
    #  ######   ######  ########  ######## ######## ##    ## #### ##    ##  ######
    # ##    ## ##    ## ##     ## ##       ##       ###   ##  ##  ###   ## ##    ##
    # ##       ##       ##     ## ##       ##       ####  ##  ##  ####  ## ##
    #  ######  ##       ########  ######   ######   ## ## ##  ##  ## ## ## ##   ####
    #       ## ##       ##   ##   ##       ##       ##  ####  ##  ##  #### ##    ##
    # ##    ## ##    ## ##    ##  ##       ##       ##   ###  ##  ##   ### ##    ##
    #  ######   ######  ##     ## ######## ######## ##    ## #### ##    ##  ######

    # @!group Membership Screening

    # Get the join requests for the guild.
    # @param limit [Integer, nil] The maximum number of join requests to fetch,
    #   or `nil` to fetch all of the matching join requests.
    # @param status [String, Symbol, nil] Filter join requests by their current status.
    # @param after [Time, #resolve_id, nil] Get join requests starting from after this point.
    # @param before [Time, #resolve_id, nil] Get join requests starting from before this point.
    # @param oldest_first [true, false, nil] Whether to return join requests in oldest to newest order.
    # @return [QueriedJoinRequests] The join requests that matched the given search query.
    def join_requests(
      status: :submitted, limit: 100, before: nil, after: nil, oldest_first: nil
    )
      if [before, after, oldest_first].count(&:itself) > 1
        raise ArgumentError, "'before', 'after', and 'oldest_first' are mutually exclusive"
      end

      options = {
        limit: limit || 100,
        status: status&.upcase&.to_sym || :SUBMITTED,
        after: after.is_a?(Time) ? Snowflake.synthesise(after) : after&.resolve_id,
        before: before.is_a?(Time) ? Snowflake.synthesise(before) : before&.resolve_id
      }.compact

      # Will store how many total join requests match the specified query.
      total = nil

      # Reverses the list and starts retrieving the oldest requests first.
      options[:after] = 0 if oldest_first

      fetch_join_requests = lambda do |**query|
        data = @bot.http.list_guild_join_requests(@id, **options, **query.compact)
        total ||= data[:total]

        data[:guild_join_requests]&.map { |item| JoinRequest.new(item, self, @bot) } || []
      end

      paginator = Paginator.new(limit, :down) do |page|
        key = if options[:status] == :SUBMMITED
                page&.last&.id
              elsif (last = page&.last)
                Snowflake.synthesise(last.reviewed_at)
              end

        if after || oldest_first
          fetch_join_requests.call(after: key)
        else
          fetch_join_requests.call(before: key)
        end
      end

      QueriedJoinRequests.new(paginator.to_a, total, @bot)
    end

    # @!endgroup

    #  ######   ##     ##    ###    ##    ## ##    ## ######## ##        ######
    #  ##    ## ##     ##   ## ##   ###   ## ###   ## ##       ##       ##    ##
    #  ##       ##     ##  ##   ##  ####  ## ####  ## ##       ##       ##
    #  ##       ######### ##     ## ## ## ## ## ## ## ######   ##        ######
    #  ##       ##     ## ######### ##  #### ##  #### ##       ##             ##
    #  ##    ## ##     ## ##     ## ##   ### ##   ### ##       ##       ##    ##
    #  ######   ##     ## ##     ## ##    ## ##    ## ######## ########  ######

    # @!group Channels

    # Get the AFK channel of the guild.
    # @return [Channel, nil] the AFK voice channel of the guild, or `nil` if none is set.
    def afk_channel
      @bot.channel(@afk_channel_id) if @afk_channel_id
    end

    # Get the rules channel of the guild.
    # @return [Channel, nil] The channel where community guilds can display rules or guidelines, or `nil` if none is set.
    def rules_channel
      @bot.channel(@rules_channel_id) if @rules_channel_id
    end

    # Get the system channel of the guild.
    # @return [Channel, nil] The system channel (used for automatic welcome messages) of a guild, or `nil` if none is set.
    def system_channel
      @bot.channel(@system_channel_id) if @system_channel_id
    end

    # Get the safety alerts channel of the guild.
    # @return [Channel, nil] The channel where Community guilds receive safety alerts from Discord, or `nil` if none is set.
    def safety_alerts_channel
      @bot.channel(@safety_alerts_channel_id) if @safety_alerts_channel_id
    end

    # Get the public updates channel of the guild.
    # @return [Channel, nil] The channel where Community guilds receive public updates from Discord, or `nil` if none is set.
    def public_updates_channel
      @bot.channel(@public_updates_channel_id) if @public_updates_channel_id
    end

    # Get a list of the category channels on the guild.
    # @return [Array<Channel>] A list of the category channels on the guild.
    def categories
      @channels.filter_map { |_, channel| channel if channel.category? }
    end

    # Get the channels in the guild that are not in a category.
    # @return [Array<Channel>] An array of channels that are not in a category.
    def orphan_channels
      @channels.filter_map { |_, channel| channel if channel.orphan? }
    end

    # Get the active threads for the guild.
    # @param bypass_cache [true, false] Whether the cached threads should
    #   be ignored and re-fetched via an HTTP request.
    # @return [Array<Channel>] The active threads for the guild.
    def active_threads(bypass_cache: false)
      if bypass_cache || !@resolved_threads
        data = @bot.http.list_active_guild_threads(@id)

        data[:members].each do |member|
          thread = data[:threads].find { |item| item[:id] == member[:id] }

          (thread[:member] = member) if thread
        end

        process_active_threads(data[:threads])
      end

      @threads.filter_map { |_, channel| channel unless channel.archived? }
    end

    # Get the channels for the guild.
    # @param bypass_cache [true, false] Whether the cached channels should be
    #   ignored and re-fetched via an HTTP request.
    # @return [Array<Channel>] The channels for the guild.
    def channels(bypass_cache: false)
      process_channels(@bot.http.list_guild_channels(@id)) if bypass_cache || !@resolved_channels

      @channels.values
    end

    # Create a new channel.
    # @param name [String] The name of the channel; between 1-100 characters.
    # @param type [Symbol, Integer, nil] The type of the channel; see {Channel::TYPES}.
    # @param topic [String, nil] The topic of the channel; between 1-4096 characters.
    # @param nsfw [true, false, nil] Whether or not to mark the channel as age-restricted.
    # @param slowmode_rate [Integer, nil] The slowmode-rate of the channel; between 0-21600 (in seconds).
    # @param parent [Channel, Integer, String, nil] The category to create the channel under, or `nil` to orphan the channel.
    # @param bitrate [Integer, nil] The bitrate of the voice or stage channel; minimum of 8000 (in bits).
    # @param user_limit [Integer, nil] The maximum number of users who can join the voice or stage channel, or `0` for no limit.
    # @param overwrites [Array<#to_h, Hash>, nil] The permission overwrite to apply to the channel.
    # @param video_quality_mode [Symbol, Integer, nil] The camera video quality mode of the voice or stage channel.
    # @param voice_region [VoiceRegion, String, Symbol, nil] The RTC voice region of the stage or voice channel.
    # @param default_auto_archive_duration [60, 1440, 4320, 10080, nil] The duration (in seconds) before threads created in the channel are hidden.
    # @param default_reaction [Integer, String, Emoji, nil] The emoji to display on threads created in the forum channel.
    # @param default_sort_order [Integer, Symbol, nil] The default order used to order threads in the forum channel.
    # @param default_layout [Integer, Symbol, nil] The default layout type used to display threads in the forum channel.
    # @param position [Integer, nil] The sorting position of the channel. Using this parameter is highly discouraged.
    # @param tags [Array<ChannelTag, #to_h>, nil] The tags that should be available in the forum channel.
    # @param flags [Array<Integer, Symbol>, Integer, Symbol, nil] The flags to set for the channel. Only `:spoiler` is curently supported.
    # @param default_thread_slowmode_rate[Integer, nil] The default slowmode rate to set on newly created threads created in the text or forum channel.
    # @param reason [String, nil] The reason to show in the guild's audit log for creating the channel.
    # @return [Channel] The channel that was created.
    def create_channel(
      name:, type:, topic: nil, nsfw: nil, slowmode_rate: nil, parent: nil,
      bitrate: nil, user_limit: nil, overwrites: nil, video_quality_mode: nil,
      voice_region: nil, default_auto_archive_duration: nil, default_reaction: nil,
      default_sort_order: nil, default_layout: nil, position: nil, tags: nil, flags: nil,
      default_thread_slowmode_rate: nil, reason: nil
    )
      data = {
        name: name,
        type: Channel::TYPES[type] || type,
        topic: topic,
        nsfw: nsfw,
        position: position,
        rate_limit_per_user: slowmode_rate,
        bitrate: bitrate,
        user_limit: user_limit,
        permission_overwrites: overwrites ? [*overwrites].map(&:to_h) : :undef,
        parent_id: parent&.resolve_id,
        rtc_region: voice_region&.to_s,
        video_quality_mode: Channel::VIDEO_QUALITIES[video_quality_mode] || video_quality_mode,
        default_auto_archive_duration: default_auto_archive_duration,
        default_reaction_emoji: default_reaction ? Emoji.build_hash(default_reaction) : nil,
        default_sort_order: Channel::SORT_ORDERS[default_sort_order] || default_sort_order,
        default_forum_layout: Channel::LAYOUTS[default_layout] || default_layout,
        default_thread_rate_limit_per_user: default_thread_slowmode_rate,
        available_tags: tags&.map(&:to_h),
        flags: [*(flags || 0)].reduce(0) { |sum, bit| sum | (Channel::FLAGS[bit] || bit.to_i) }
      }

      @bot.ensure_channel(@bot.http.create_guild_channel(@id, **data.compact, reason: reason), self)
    end

    # Search the messages that have been sent in the guild.
    # @example Search for 200 messages from a user that contain an attachment.
    #  options = {
    #    limit: 200,
    #    contains: :file,
    #    authors: 171764626755813376
    #  }
    #
    #  results = guild.search_messages(**options)
    # @example Search for all of the messages in a channel that mentions someone.
    #  options = {
    #    limit: nil,
    #    mentions: 171764626755813376,
    #    channels: 381891448884428801
    #  }
    #
    #  results = guild.search_messages(**options)
    # @example Search for 105 messages that contain specific embed types, sorted by oldest to newest.
    #  options = {
    #    limit: 105,
    #    embed_types: %i[article image],
    #    sort_order: :ascending
    #  }
    #
    #  results = guild.search_messages(**options)
    # @example Search for 30 messages sent between two dates that contain the word “time” and an @everyone ping.
    #  options = {
    #    limit: 30,
    #    content: 'time',
    #    mentions_everyone: true,
    #    after: Time.parse("December 16th, 2020"),
    #    before: Time.parse("December 25th, 2020")
    #  }
    #
    #  results = guild.search_messages(**options)
    # @example Search for 500 messages that reply to a specific message, contain a Ruby file, and were sent by a bot account.
    #  options = {
    #    limit: 500,
    #    author_types: :bot,
    #    file_extensions: '.rb',
    #    reply_messages: 1454184993923268660
    #  }
    #
    #  results = guild.search_messages(**options)
    # @param limit [Integer, nil] The maximum number of messages to return, or `nil` to fetch all of the messages that match the search query.
    # @param offset [Integer, nil] The number of messages between 0-9975 to offset the search query by.
    # @param before [Time, #resolve_id, nil] Get messages sent before this timestamp.
    # @param after [Time, #resolve_id, nil] Get messages sent after this timestamp.
    # @param content [String, #to_s, nil] Get messages with matching message content.
    # @param slop [Integer, nil] The amount of variation allowed between the placement of words when matching against message content; between 0-100.
    # @param channels [Array<Channel, Integer, String>, Channel, Integer, String, nil] Get messages that were sent in these channels.
    # @param authors [Array<#resolve_id>, #resolve_id, nil] Get messages that were created by these authors.
    # @param author_types [Array<String, Symbol>, String, Symbol, nil] Get messages that were created by these author types: `user`, `bot`, or `webhook`.
    # @param mentions [Array<#resolve_id>, #resolve_id, nil] Get messages that mention these users or members.
    # @param role_mentions [Array<Role, Integer, String>, Role, Integer, String, nil] Get messages that mention these roles.
    # @param mentions_everyone [true, false, nil] Get messages that mention the @everyone role.
    # @param reply_users [Array<#resolve_id>, #resolve_id, nil] Get messages that replied to these users or members.
    # @param reply_messages [Array<Message, Integer, String>, Message, Integer, String, nil] Get messages that replied to these messages.
    # @param pinned [true, false, nil] Get messages that are pinned.
    # @param contains [Array<String, Symbol>, String, Symbol, nil] Get messages that contain specific fields, e.g. `file`, `poll`, `sound`, etc.
    # @param embed_types [Array<String, Symbol>, String, Symbol, nil] Get messages that contain matching embed types.
    # @param embed_providers [Array<String, Symbol>, String, Symbol, nil] Get messages that contain embeds from specific providers.
    # @param link_hosts [Array<String, Symbol>, String, Symbol, nil] Get messages that contain matching link hostnames, e.g. `discord.com`.
    # @param file_names [Array<String, Symbol, Attachment>, String, Symbol, Attachment, nil] Get messages that contain matching attachment filenames.
    # @param file_extensions [Array<String, Symbol>, String, Symbol, nil] Get messages that contain matching attachment file extensions, e.g. `.rb`, `.mp3`, etc.
    # @param include_nsfw [true, false, nil] Whether or not to include messages that have been sent in NSFW channels.
    # @param sort_by [Symbol, String, nil] Whether to sort the returned messages by their `:creation_time`, or `:relevance` to the search query.
    # @param sort_order [Symbol, string, nil] Whether to order the returned messages in `:descending`, or `:ascending` order. Not respected when sorting by `:relevance`.
    # @raise [Discordrb::Errors::NoPermission] This may occur when the application has not enabled the `MESSAGE_CONTENT` privileged intent on the Discord Developer Portal.
    # @note Messages with GIFs sent before February 24th, 2026 may not be returned under the `gif` embed type when using the `embed_types:` parameter.
    # @note Messages fetched via this method will not contain reactions. This means that {Message#reactions} will **always** return an empty array, even if the message has reactions.
    # @return [SearchedMessages] the results of the search query.
    def search_messages(
      limit: 25, offset: nil, before: nil, after: nil, content: nil, slop: 2, channels: nil, authors: nil, author_types: nil,
      mentions: nil, role_mentions: nil, mentions_everyone: nil, reply_users: nil, reply_messages: nil, pinned: nil, contains: nil,
      embed_types: nil, embed_providers: nil, link_hosts: nil, file_names: nil, file_extensions: nil, include_nsfw: true, sort_by: nil,
      sort_order: :descending
    )
      sort_order = case sort_order&.to_sym
                   when nil, :desc, :descending, :newest_first
                     :desc
                   when :asc, :ascending, :oldest_first
                     :asc
                   else
                     raise ArgumentError, "Invalid value for the 'sort_order' parameter"
                   end

      sort_by = case sort_by&.to_sym
                when nil, :timestamp, :creation_time
                  :timestamp
                when :relevance, :match_score
                  :relevance
                else
                  raise ArgumentError, "Invalid value for the 'sort_by' parameter"
                end

      options = {
        limit: limit && limit <= 25 ? limit : 25,
        max_id: before.is_a?(Time) ? Snowflake.synthesise(before) : before&.resolve_id,
        min_id: after.is_a?(Time) ? Snowflake.synthesise(after) : after&.resolve_id,
        offset: offset || 0,
        slop: slop,
        content: content&.to_s,
        channel_id: channels ? [*channels].map(&:resolve_id) : channels,
        author_type: author_types ? [*author_types] : author_types,
        author_id: authors ? [*authors].map(&:resolve_id) : authors,
        mentions: mentions ? [*mentions].map(&:resolve_id) : mentions,
        mentions_role_id: role_mentions ? [*role_mentions].map(&:resolve_id) : role_mentions,
        mention_everyone: mentions_everyone,
        replied_to_user_id: reply_users ? [*reply_users].map(&:resolve_id) : reply_users,
        replied_to_message_id: reply_messages ? [*reply_messages].map(&:resolve_id) : reply_messages,
        pinned: pinned,
        has: contains ? [*contains] : contains,
        embed_type: embed_types ? [*embed_types] : embed_types,
        embed_provider: embed_providers ? [*embed_providers] : embed_providers,
        link_hostname: link_hosts ? [*link_hosts] : link_hosts,
        attachment_filename: ([*file_names].map { |file| file.is_a?(Attachment) ? file.filename : file } if file_names),
        attachment_extension: file_extensions ? [*file_extensions].map { |type| type.to_s.delete_prefix('.') } : file_extensions,
        sort_by: sort_by,
        sort_order: sort_order,
        include_nsfw: include_nsfw
      }.compact

      raise ArgumentError, "The 'role_mentions' parameter cannot contain the default role" if options[:mentions_role_id]&.any?(@id)

      # Only store the total message count from the first request.
      total = nil

      get_messages = lambda do |query|
        data = @bot.http.search_guild_messages(@id, **options, **query.compact)
        total ||= data[:total_results]

        data[:threads]&.each do |thread|
          thread[:member] = data[:members]&.find { |member| thread[:id] == member[:id] }

          @bot.ensure_channel(thread, self)
        end

        data[:messages].collect { |nested_messages| Message.new(nested_messages[0], @bot) }
      end

      paginator = Paginator.new(limit, :down) do |page|
        if sort_by == :relevance
          if (count = (paginator.amount_fetched + options[:offset])) > 9975
            []
          else
            get_messages.call(offset: count)
          end
        elsif sort_order == :desc
          get_messages.call(max_id: page&.last&.id, offset: page ? 0 : nil)
        else
          get_messages.call(min_id: page&.last&.id, offset: page ? 0 : nil)
        end
      end

      SearchedMessages.new(paginator.to_a, total, @bot)
    end

    # @!endgroup

    #   ######  ##    ##  ######  ######## ######## ##     ##      ######## ##          ###     ######    ######
    #  ##    ##  ##  ##  ##    ##    ##    ##       ###   ###      ##       ##         ## ##   ##    ##  ##    ##
    #  ##         ####   ##          ##    ##       #### ####      ##       ##        ##   ##  ##        ##
    #   ######     ##     ######     ##    ######   ## ### ##      ######   ##       ##     ## ##   ####  ######
    #        ##    ##          ##    ##    ##       ##     ##      ##       ##       ######### ##    ##        ##
    #  ##    ##    ##    ##    ##    ##    ##       ##     ##      ##       ##       ##     ## ##    ##  ##    ##
    #   ######     ##     ######     ##    ######## ##     ##      ##       ######## ##     ##  ######    ######

    # @!group System Channel Notifications

    # @!method join_notifications?
    #   @return [true, false] whether or not the guild has enabled member join notifications.
    # @!method premium_notifications?
    #   @return [true, false] whether or not the guild has enabled guild boost notifications.
    # @!method reminder_notifications?
    #   @return [true, false] whether or not the guild has enabled guild setup tips.
    # @!method join_notification_replies?
    #   @return [true, false] whether or not the guild has enabled the member join sticker reply buttons.
    # @!method role_subscription_notifications?
    #   @return [true, false] whether or not the guild has enabled role subscription purchase notifications.
    # @!method role_subscription_notification_replies?
    #   @return [true, false] whether or not the guild has enabled the role subscription purchase sticker reply buttons.
    SYSTEM_CHANNEL_FLAGS.each do |name, value|
      define_method("#{name}?") do
        @system_channel_id ? @system_channel_flags.nobits?(value) : false
      end
    end

    # @!endgroup

    #  ######## ##     ##  #######        ## ####  ######
    #  ##       ###   ### ##     ##       ##  ##  ##    ##
    #  ##       #### #### ##     ##       ##  ##  ##
    #  ######   ## ### ## ##     ##       ##  ##   ######
    #  ##       ##     ## ##     ## ##    ##  ##        ##
    #  ##       ##     ## ##     ## ##    ##  ##  ##    ##
    #  ######## ##     ##  #######   ######  ####  ######

    # @!group Emojis

    # Get the emojis for the guild.
    # @param bypass_cache [true, false] Whether the cached emojis should
    #   be ignored and re-fetched via an HTTP request.
    # @return [Array<Emoji>] The emojis that have been added to the guild.
    def emojis(bypass_cache: false)
      process_emojis(@bot.http.list_guild_emojis(@id)) if bypass_cache

      @emojis.values
    end

    # Get a specific emoji on the guild.
    # @param emoji_id [Integer, String, Sound] The ID of the emoji to get.
    # @param request [true, false] Whether to fallback to an HTTP request and fetch the emoji if it isn't cached.
    # @return [Emoji, nil] The emoji that was identified, or `nil` if there wasn't an emoji with the given ID.
    def emoji(emoji_id, request: false)
      id = emoji_id.resolve_id
      emoji = @emojis[id]
      return emoji if emoji || !request

      response = @bot.http.get_guild_emoji(@id, id)
      Emoji.new(response, @bot, self).tap { |emoji| cache_emoji(emoji) }
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Create a new emoji.
    # @param name [String] The 2-32 character name of the emoji.
    # @param file [File, #read] A file-like object that responds to `#read`.
    # @param roles [Array<Role, Integer, String>, nil] The roles that are allowed to use the emoji.
    # @param reason [String, nil] The reason to show in the guild's audit log for creating the emoji.
    # @return [Emoji] The emoji that was created.
    def create_emoji(name:, file:, roles: nil, reason: nil)
      data = {
        name: name.to_s,
        roles: roles ? [*roles].map(&:resolve_id) : :undef,
        image: file.respond_to?(:read) ? Discordrb.encode64(file) : file
      }

      response = @bot.http.create_guild_emoji(@id, **data, reason:)
      Emoji.new(response, @bot, self).tap { |emoji| cache_emoji(emoji) }
    end

    # @!endgroup

    #  ##     ##    ## #### ########   ######   ######## ########
    #  ##     ##    ##  ##  ##     ## ##    ##  ##          ##
    #  ##     ##    ##  ##  ##     ## ##        ##          ##
    #  ##     ##    ##  ##  ##     ## ##   #### ######      ##
    #  ##    ####   ##  ##  ##     ## ##    ##  ##          ##
    #  ##    ####   ##  ##  ##     ## ##    ##  ##          ##
    #    ###    ###    #### ########   ######   ########    ##

    # @!group Widget

    # Check if the guild has enabled the widget.
    # @return [true, false] Whether or not the guild has enabled the widget.
    def widget_enabled?
      cache_widget
      @widget_enabled
    end

    # Get the channel used to invite members for the widget.
    # @return [Channel, nil] The channel used to generate invites for the widget, or `nil`.
    def widget_channel
      cache_widget
      @bot.channel(@widget_channel_id) if @widget_channel_id
    end

    # Get a URL to an image that can be used to display the guild widget on the internet.
    # @param style [String, Symbol, nil] The styling of the widget image. Can be set to one of the
    #   following values: `shield` (default), `banner1`, `banner2`, `banner3`, or `banner4`.
    # @return [String, nil] The URL to the widget's image, or `nil` if the widget has been disabled.
    def widget_url(style: :shield)
      Assets[:guild_widget, @id, style: style || :shield] if widget?
    end

    alias_method :widget?, :widget_enabled?

    # @!endgroup

    #  #### ##    ## ##     ## #### ######## ########  ######
    #   ##  ###   ## ##     ##  ##     ##    ##       ##    ##
    #   ##  ####  ## ##     ##  ##     ##    ##       ##
    #   ##  ## ## ## ##     ##  ##     ##    ######    ######
    #   ##  ##  ####  ##   ##   ##     ##    ##             ##
    #   ##  ##   ###   ## ##    ##     ##    ##       ##    ##
    #  #### ##    ##    ###    ####    ##    ########  ######

    # @!group Invites

    # Get the invites for the guild.
    # @return [Array<Invite>] The invites for the guild.
    def invites
      response = @bot.http.list_guild_invites(@id)
      response.map { |invite| Invite.new(invite, true, @bot) }
    end

    # Get an invite URL to the guild using the {#vanity_invite_code vanity invite code}.
    # @return [String, nil] An invite link to the guild made using the vanity invite code.
    def vanity_invite_link
      "https://discord.gg/#{@vanity_invite_code}" if @vanity_invite_code
    end

    # Get the vanity invite for the guild.
    # @return [VanityInvite, nil] The vanity invite for the guild, or `nil` if one isn't set.
    # @note The `MANAGE_GUILD` permission is required for {VanityInvite#usage_count} to be set.
    def vanity_invite
      if bot.can_manage_guild?
        begin
          base = @bot.http.get_guild_vanity_url(@id)
        rescue Discordrb::Errors::NoPermission
          return nil
        end
      end

      return unless @vanity_invite_code ||= base&.[](:code)

      data = @bot.http.get_invite(@vanity_invite_code)

      (data[:uses] = base[:uses] || 0) if base

      VanityInvite.new(data, self, @bot)
    end

    alias_method :vanity_invite_url, :vanity_invite_link

    # @!endgroup

    #  ########  ########  ##     ## ##    ## ########
    #  ##     ## ##     ## ##     ## ###   ## ##
    #  ##     ## ##     ## ##     ## ####  ## ##
    #  ########  ########  ##     ## ## ## ## ######
    #  ##        ##   ##   ##     ## ##  #### ##
    #  ##        ##    ##  ##     ## ##   ### ##
    #  ##        ##     ##  #######  ##    ## ########

    # @!group Prune

    # Get the prune count for the guild.
    # @param days [Integer] The number of days to count for the prune; between 1-30.
    # @param roles [Array<Integer, String, Role>, nil] Include members with these roles.
    # @return [Integer] The amount of members that would be removed in a prune operation.
    # @raise [ArgumentError] If the `days:` parameter is not an {Integer} between 1-30 (inclusive).
    def prune_count(days:, roles: nil)
      raise ArgumentError, "'days' must be between 1-30" unless days.between?(1, 30)

      roles = roles ? [*roles].map(&:resolve_id) : :undef

      @bot.http.get_guild_prune_count(@id, days: days, include_roles: roles)[:pruned]
    end

    # Begin a prune operation to kick inactive members.
    # @param days [Integer] The days worth of inactivity to prune; between 1-30.
    # @param with_count [true, false] Whether the prune count should be returned.
    # @param roles [Array<Integer, String, Role>, nil] Include members with these roles.
    # @param reason [String, nil] The reason to show in the guild's audit log for the prune.
    # @return [Integer, nil] The amount of members that were removed in the prune operation, or
    #   `nil` if the `with_count:` parameter was set to `false`.
    # @raise [ArgumentError] If the `days:` parameter is not an {Integer} between 1-30 (inclusive).
    def prune_members(days:, with_count: true, roles: nil, reason: nil)
      raise ArgumentError, "'days' must be between 1-30" unless days.between?(1, 30)

      data = {
        days: days,
        compute_prune_count: with_count || false,
        include_roles: roles ? [*roles].map(&:resolve_id) : :undef
      }

      @bot.http.begin_guild_prune(@id, **data, reason: reason)[:pruned]
    end

    # @!endgroup

    #  ########     ###    ##    ##  ######
    #  ##     ##   ## ##   ###   ## ##    ##
    #  ##     ##  ##   ##  ####  ## ##
    #  ########  ##     ## ## ## ##  ######
    #  ##     ## ######### ##  ####       ##
    #  ##     ## ##     ## ##   ### ##    ##
    #  ########  ##     ## ##    ##  ######

    # @!group Bans

    # Unban a user from the guild.
    # @param user [User, Member, Integer, String] The user to unban.
    # @param reason [String, nil] The reason to show in the guild's audit log for un-banning the user.
    # @return [nil]
    def unban(user, reason: nil)
      @bot.http.remove_guild_ban(@id, user.resolve_id, reason:)
      nil
    end

    # Ban a user from the guild.
    # @param user [User, Member, Integer, String] The user to ban.
    # @param delete_messages [Integer, nil] Delete messages going back by this amount of seconds.
    # @param reason [String, nil] The reason to show in the guild's audit log for banning the user.
    # @return [nil]
    def ban(user, delete_messages: nil, reason: nil)
      data = {
        reason: reason,
        delete_message_seconds: delete_messages || :undef
      }

      @bot.http.create_guild_ban(@id, user.resolve_id, **data)
      nil
    end

    # Ban multiple users from the guild in a single operation.
    # @param users [Array<User, Member, Integer, String>] The 1-200 users that should be banned.
    # @param delete_messages [Integer, nil] Delete messages going back by this amount of seconds.
    # @param reason [String, nil] The reason to show in the guild's audit log for banning the users.
    # @raise [ArgumentError] If the `users` parameter is not an array between 1-200 elements in size.
    # @return [BulkBan] The resulting data from the ban operation.
    def bulk_ban(users, delete_messages: nil, reason: nil)
      users = [*users].map(&:resolve_id)
      raise ArgumentError, 'Can only ban 1-200 users' unless users.size.between?(1, 200)

      data = {
        reason: reason,
        user_ids: users,
        delete_message_seconds: delete_messages || :undef
      }

      response = @bot.http.bulk_guild_ban(@id, **data)
      BulkBan.new(response, self, reason)
    rescue Discordrb::Errors::UnableToBulkBanUsers
      BulkBan.new({ failed_users: users }, self, reason)
    end

    # Get the users who have been banned from the guild.
    # @param user [User, Integer, String, nil] Get a ban for a specific user.
    # @param limit [Integer, nil] The max number of bans to return, or `nil` for no limit.
    # @param after [User, Member, Time, Integer, String, nil] Get bans after this user ID.
    # @param before [User, Member, Time, Integer, String, nil] Get bans before this user ID.
    # @return [Array<GuildBan>] The users who have been banned from the guild.
    # @note When using the `user:` parameter only a single ban can be returned at most.
    # @note When using the `before:` parameter, bans will be sorted in descending order by user ID
    #   (newest users first), and in ascending order by user ID (oldest users first) otherwise.
    def bans(limit: 1000, user: nil, before: nil, after: nil)
      if [before, after, user].count(&:itself) > 1
        raise ArgumentError, "'before', 'after', and 'user' are mutually exclusive"
      end

      if user
        begin
          single_ban = @bot.http.get_guild_ban(@id, user.resolve_id)
          return [GuildBan.new(single_ban, self, @bot)]
        rescue Discordrb::Errors::NotFound
          return []
        end
      end

      options = {
        limit: limit && limit <= 1000 ? limit : 1000,
        after: after.is_a?(Time) ? Snowflake.synthesise(after) : after&.resolve_id,
        before: before.is_a?(Time) ? Snowflake.synthesise(before) : before&.resolve_id
      }

      get_bans = lambda do |**query|
        response = @bot.http.list_guild_bans(@id, **options, **query.compact)
        response.collect { |banned_data| GuildBan.new(banned_data, self, @bot) }
      end

      paginator = Paginator.new(limit, before ? :up : :down) do |page|
        if before
          get_bans.call(before: page&.first&.user&.id)
        else
          get_bans.call(after: page&.last&.user&.id)
        end
      end

      paginator.to_a
    end

    # @!endgroup

    #   ######   ######  ##     ## ######## ########  ##     ## ##       ######## ########
    #  ##    ## ##    ## ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #  ##       ##       ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #   ######  ##       ######### ######   ##     ## ##     ## ##       ######   ##     ##
    #        ## ##       ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #  ##    ## ##    ## ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #   ######   ######  ##     ## ######## ########   #######  ######## ######## ########
    #
    #  ######## ##     ## ######## ##    ## ########  ######
    #  ##       ##     ## ##       ###   ##    ##    ##    ##
    #  ##       ##     ## ##       ###   ##    ##    ##
    #  ######   ##     ## ######   ## ## ##    ##     ######
    #  ##        ##   ##  ##       ##  ####    ##          ##
    #  ##         ## ##   ##       ##   ###    ##    ##    ##
    #  ########    ###    ######## ##    ##    ##     ######

    # @!group Scheduled Events

    # Get the scheduled events for the guild.
    # @param bypass_cache [true, false] Whether the cached scheduled
    #   events should be ignored and re-fetched via an HTTP request.
    # @return [Array<ScheduledEvent>] The scheduled events for the guild.
    def scheduled_events(bypass_cache: false)
      process_scheduled_events(@bot.http.list_guild_scheduled_events(@id, with_user_count: true)) if bypass_cache

      @scheduled_events.values
    end

    # Get a specific scheduled event on the guild.
    # @param scheduled_event_id [Integer, String, ScheduledEvent] The scheduled event to get.
    # @param request [true, false] Whether to request the event from discord if it isn't cached.
    # @return [ScheduledEvent, nil] The scheduled event for the ID, or `nil` if it couldn't be found.
    def scheduled_event(scheduled_event_id, request: true)
      id = scheduled_event_id.resolve_id
      cached = @scheduled_events[id]
      return cached if cached || !request

      event = @bot.http.get_guild_scheduled_event(@id, id, with_user_count: true)
      scheduled_event = ScheduledEvent.new(event, self, @bot)
      @scheduled_events[scheduled_event.id] = scheduled_event
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Create a new scheduled event.
    # @param name [String] The 1-100 character name of the scheduled event.
    # @param start_time [Time] The start time of the scheduled event.
    # @param entity_type [Integer, Symbol] The entity type of the scheduled event.
    # @param end_time [Time, nil] The end time of the scheduled event.
    # @param channel [Integer, Channel, String, nil] The channel where the scheduled event will take place.
    # @param location [String, nil] The external location of the scheduled event.
    # @param description [String, nil] The 1-1000 character description of the scheduled event.
    # @param cover [File, #read, nil] The cover image of the scheduled event.
    # @param recurrence_rule [#to_h, nil] The recurrence rule of the scheduled event.
    # @param reason [String, nil] The reason to show in the guild's audit log for creating the scheduled event.
    # @yieldparam builder [ScheduledEvent::RecurrenceRule::Builder] An optional recurrence rule builder.
    # @return [ScheduledEvent] The scheduled event that was created.
    def create_scheduled_event(
      name:, start_time:, entity_type:, end_time: nil, channel: nil, location: nil,
      description: nil, cover: nil, recurrence_rule: nil, reason: nil
    )
      data = {
        name: name,
        privacy_level: 2,
        scheduled_start_time: start_time&.iso8601,
        entity_type: ScheduledEvent::ENTITY_TYPES[entity_type] || entity_type,
        channel_id: channel&.resolve_id,
        entity_metadata: location ? { location: location } : nil,
        scheduled_end_time: end_time&.iso8601,
        description: description,
        image: cover.respond_to?(:read) ? Discordrb.encode64(cover) : cover,
        recurrence_rule: block_given? || recurrence_rule&.to_h
      }

      if block_given?
        yield((builder = ScheduledEvent::RecurrenceRule::Builder.new))
        data[:recurrence_rule] = builder.tap(&:check).to_h
      end

      event = @bot.http.create_guild_scheduled_event(@id, **data.compact, reason:)
      scheduled_event = ScheduledEvent.new(event, self, @bot)
      @scheduled_events[scheduled_event.id] = scheduled_event
    end

    # @!endgroup

    #   ######  ######## ####  ######  ##    ## ######## ########   ######
    #  ##    ##    ##     ##  ##    ## ##   ##  ##       ##     ## ##    ##
    #  ##          ##     ##  ##       ##  ##   ##       ##     ## ##
    #   ######     ##     ##  ##       #####    ######   ########   ######
    #        ##    ##     ##  ##       ##  ##   ##       ##   ##         ##
    #  ##    ##    ##     ##  ##    ## ##   ##  ##       ##    ##  ##    ##
    #   ######     ##    ####  ######  ##    ## ######## ##     ##  ######

    # @!group Stickers

    # Get the stickers for the guild.
    # @param bypass_cache [true, false] Whether the cached stickers should be
    #   ignored and re-fetched via an HTTP request.
    # @return [Array<Sticker>] The stickers that have been added to the guild.
    def stickers(bypass_cache: false)
      process_stickers(@bot.http.list_guild_stickers(@id)) if bypass_cache

      @stickers.values
    end

    # Get a specific sticker on the guild.
    # @param sticker_id [Integer, String] The ID of the sticker to get.
    # @param request [true, false] Whether to fallback to an HTTP request and fetch the sticker if it isn't cached.
    # @return [Sticker, nil] The sticker that was identified, or `nil` if there wasn't a sticker with the given ID.
    def sticker(sticker_id, request: false)
      id = sticker_id.resolve_id
      sticker = @stickers[id]
      return sticker if sticker || !request

      response = @bot.http.get_guild_sticker(@id, id)
      Sticker.new(response, self, @bot).tap { |sticker| @stickers[sticker.id] = sticker }
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Create a new sticker.
    # @param name [String] The 2-30 character name of the sticker.
    # @param file [File, #read] A file-like object that responds to `#read`.
    # @param tags [Array<String>, String, nil] The 1-200 character tags of the sticker.
    # @param description [String, #to_s, nil] The 1-100 character description of the sticker.
    # @param reason [String, nil] The reason to show in the guild's audit log for creating the sticker.
    # @return [Sticker] The sticker that was created.
    def create_sticker(name:, file:, tags:, description: nil, reason: nil)
      unless file.respond_to?(:read)
        raise ArgumentError, "the 'file' parameter must respond to #read"
      end

      data = {
        name: name,
        file: file,
        description: description.to_s,
        tags: tags.is_a?(Array) ? tags.join(', ') : tags
      }

      response = @bot.http.create_guild_sticker(@id, **data, reason: reason)
      Sticker.new(response, self, @bot).tap { |sticker| @stickers[sticker.id] = sticker }
    end

    # @!endgroup

    #   ######   #######  ##     ## ##    ## ########  ########   #######     ###    ########  ########
    #  ##    ## ##     ## ##     ## ###   ## ##     ## ##     ## ##     ##   ## ##   ##     ## ##     ##
    #  ##       ##     ## ##     ## ####  ## ##     ## ##     ## ##     ##  ##   ##  ##     ## ##     ##
    #   ######  ##     ## ##     ## ## ## ## ##     ## ########  ##     ## ##     ## ########  ##     ##
    #        ## ##     ## ##     ## ##  #### ##     ## ##     ## ##     ## ######### ##   ##   ##     ##
    #  ##    ## ##     ## ##     ## ##   ### ##     ## ##     ## ##     ## ##     ## ##    ##  ##     ##
    #   ######   #######   #######  ##    ## ########  ########   #######  ##     ## ##     ## ########
    #
    #   ######   #######  ##     ## ##    ## ########   ######
    #  ##    ## ##     ## ##     ## ###   ## ##     ## ##    ##
    #  ##       ##     ## ##     ## ####  ## ##     ## ##
    #   ######  ##     ## ##     ## ## ## ## ##     ##  ######
    #        ## ##     ## ##     ## ##  #### ##     ##       ##
    #  ##    ## ##     ## ##     ## ##   ### ##     ## ##    ##
    #   ######   #######   #######  ##    ## ########   ######

    # @!group Soundboard Sounds

    # Get the soundboard sounds for the guild.
    # @param bypass_cache [true, false] Whether the cached soundboard sounds should be
    #   ignored and re-fetched via an HTTP request.
    # @return [Array<SoundboardSound>] The soundboard sounds that have been added to the guild.
    def soundboard_sounds(bypass_cache: false)
      process_soundboard_sounds(@bot.http.list_guild_soundboard_sounds(@id)[:items]) if bypass_cache

      @soundboard_sounds.values
    end

    # Get a specific soundboard sound on the guild.
    # @param soundboard_sound_id [Integer, String, Sound] The ID of the soundboard sound to get.
    # @param request [true, false] Whether to fallback to an HTTP request and fetch the soundboard sound if it isn't cached.
    # @return [SoundboardSound, nil] The soundboard sound that was identified, or `nil` if there wasn't a soundboard sound with the given ID.
    def soundboard_sound(soundboard_sound_id, request: true)
      id = soundboard_sound_id.resolve_id
      sound = @soundboard_sounds[id]
      return sound if sound || !request

      response = @bot.http.get_guild_soundboard_sound(@id, id)
      SoundboardSound.new(response, self, @bot).tap { |sound| cache_soundboard_sound(sound) }
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Create a new soundboard sound.
    # @param name [String] The 2-32 character name of the soundboard sound to create.
    # @param file [File, #read] An MP3 or OGG file containing the data for the soundboard sound.
    # @param volume [Numeric, nil] The volume of the soundboard sound between 0-1. Defaults to 1.
    # @param emoji [Emoji, Integer, String, nil] The emoji to display when using the soundboard sound.
    # @param reason [String, nil] The reason to show in the audit log for creating the soundboard sound.
    # @return [SoundboardSound] The soundboard sound that was created.
    def create_soundboard_sound(name:, file:, volume: nil, emoji: nil, reason: nil)
      data = {
        name: name,
        volume: volume&.to_f,
        sound: Discordrb.encode64(file),
        **(emoji ? Emoji.build_hash(emoji) : {})
      }

      response = @bot.http.create_guild_soundboard_sound(@id, **data.compact, reason: reason)
      SoundboardSound.new(response, self, @bot).tap { |sound| cache_soundboard_sound(sound) }
    end

    # @!endgroup

    #     ###    ##     ## ########  #######  ##     ##  #######  ########
    #    ## ##   ##     ##    ##    ##     ## ###   ### ##     ## ##     ##
    #   ##   ##  ##     ##    ##    ##     ## #### #### ##     ## ##     ##
    #  ##     ## ##     ##    ##    ##     ## ## ### ## ##     ## ##     ##
    #  ######### ##     ##    ##    ##     ## ##     ## ##     ## ##     ##
    #  ##     ## ##     ##    ##    ##     ## ##     ## ##     ## ##     ##
    #  ##     ##  #######     ##     #######  ##     ##  #######  ########
    #
    #  ########  ##     ## ##       ########  ######
    #  ##     ## ##     ## ##       ##       ##    ##
    #  ##     ## ##     ## ##       ##       ##
    #  ########  ##     ## ##       ######    ######
    #  ##   ##   ##     ## ##       ##             ##
    #  ##    ##  ##     ## ##       ##       ##    ##
    #  ##     ##  #######  ######## ########  ######

    # @!group Auto Moderation Rules

    # Get the auto moderation rules for the guild.
    # @param bypass_cache [true, false] Whether or not the cached auto moderation
    #   rules should be ignored and re-fetched via an HTTP request.
    # @return [Array<AutoModRule>] the configured auto moderation rules for the guild.
    def automod_rules(bypass_cache: false)
      return @automod_rules.values if @automod_fetched && !bypass_cache

      response = @bot.http.list_auto_moderation_rules(@id)

      if @bot.gateway.intents.anybits?(INTENTS[:guild_automod])
        # Replace the cache entirely if we're fetching everything.
        @automod_rules = {}

        response.each do |value|
          automod_rule = AutoModRule.new(value, self, @bot)
          @automod_rules[automod_rule.resolve_id] = automod_rule
        end

        # So we don't make requests all the time with the intent.
        @automod_fetched = true

        return @automod_rules.values
      end

      response.collect { |value| AutoModRule.new(value, self, @bot) }
    end

    # Get a specific auto moderation rule on the guild.
    # @param rule_id [Integer, String, AutoModRule] The ID of the auto moderation rule to get.
    # @param request [true, false] If the auto moderation rule should be fetched from Discord if it isn't cached.
    # @return [AutoModRule, nil] the auto moderation rule for the given ID, or `nil` if it was unable to be found.
    def automod_rule(rule_id, request: true)
      id = rule_id.resolve_id
      intent = @bot.gateway.intents.anybits?(INTENTS[:guild_automod])
      return @automod_rules[id] if (@automod_rules[id] && intent) || !request

      response = @bot.http.get_auto_moderation_rule(@id, id)
      automod_rule = AutoModRule.new(response, self, @bot)
      intent ? (@automod_rules[automod_rule.id] = automod_rule) : automod_rule
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Create a new auto moderation rule.
    # @param name [String] The 1-100 character name of the auto moderation rule.
    # @param event_type [Integer, Symbol] The event type of the auto moderation rule; see {AutoModRule::EVENT_TYPES EVENT_TYPES}.
    # @param trigger_type [Integer, Symbol] The trigger type of the auto moderation rule; see {AutoModRule::Trigger::TYPES TRIGGER_TYPES}.
    # @param actions [Array<#to_h>, nil] The actions to execute when the auto moderation rule is triggered.
    # @param enabled [true, false, nil] Whether or not the auto moderation rule should be enabled.
    # @param exempt_roles [Array<Integer, String, Role>] The roles that should be ignored by the auto moderation rule.
    # @param exempt_channels [Array<Integer, String, Channel>] The channels that should be ignored by the auto moderation rule.
    # @param mention_limit [Integer] The max amount of role and user mentions allowed per message; max 50.
    # @param keyword_filter [Array<String>, nil] The substrings which will be searched for in content; max 1000.
    # @param regex_patterns [Array<String>, nil] The regular expression patterns (rust flavoured) to match against in content; max 10.
    # @param exempt_keywords [Array<String>, nil] The substrings which should not trigger the auto moderation rule; max 1000.
    # @param keyword_presets [Array<Integer, Symbol>, nil] The pre-defined set of keywords to match against in content; see {AutoModRule::Trigger::PRESET_TYPES PRESET_TYPES}.
    # @param mention_raid_protection [true, false, nil] Whether or not to automatically detect when a mention raid is occuring.
    # @param reason [String, nil] The reason to show in the guild's audit for creating the auto moderation rule.
    # @yieldparam builder [AutoModRule::Action::Builder] An optional builder for auto moderation actions. Overrides the `actions:` argument if passed.
    # @return [AutoModRule] The auto moderation rule that was created.
    def create_automod_rule(
      name:, event_type:, trigger_type:, actions: nil, enabled: false, exempt_roles: nil, exempt_channels: nil,
      keyword_filter: nil, regex_patterns: nil, keyword_presets: nil, exempt_keywords: nil, mention_limit: nil,
      mention_raid_protection: nil, reason: nil
    )
      yield((builder = AutoModRule::Action::Builder.new)) if block_given?

      trigger = {
        allow_list: exempt_keywords,
        keyword_filter: keyword_filter,
        regex_patterns: regex_patterns,
        mention_total_limit: mention_limit,
        mention_raid_protection_enabled: mention_raid_protection,
        presets: keyword_presets&.map { |value| AutoModRule::Trigger::PRESET_TYPES[value] || value }
      }.compact

      data = {
        name: name,
        enabled: enabled,
        exempt_roles: exempt_roles&.map(&:resolve_id),
        trigger_metadata: trigger.empty? ? nil : trigger,
        exempt_channels: exempt_channels&.map(&:resolve_id),
        actions: block_given? ? builder&.to_a : actions&.map(&:to_h),
        event_type: AutoModRule::EVENT_TYPES[event_type] || event_type,
        trigger_type: AutoModRule::Trigger::TYPES[trigger_type] || trigger_type
      }.compact

      response = @bot.http.create_auto_moderation_rule(@id, **data, reason: reason)
      automod_rule = AutoModRule.new(response, self, @bot)
      @automod_rules[automod_rule.resolve_id] = automod_rule
    end

    # @!endgroup

    #  #### ##    ##  ######  #### ########  ######## ##    ## ########
    #   ##  ###   ## ##    ##  ##  ##     ## ##       ###   ##    ##
    #   ##  ####  ## ##        ##  ##     ## ##       ####  ##    ##
    #   ##  ## ## ## ##        ##  ##     ## ######   ## ## ##    ##
    #   ##  ##  #### ##        ##  ##     ## ##       ##  ####    ##
    #   ##  ##   ### ##    ##  ##  ##     ## ##       ##   ###    ##
    #  #### ##    ##  ######  #### ########  ######## ##    ##    ##
    #
    #     ###     ######  ######## ####  #######  ##    ##  ######
    #    ## ##   ##    ##    ##     ##  ##     ## ###   ## ##    ##
    #   ##   ##  ##          ##     ##  ##     ## ####  ## ##
    #  ##     ## ##          ##     ##  ##     ## ## ## ##  ######
    #  ######### ##          ##     ##  ##     ## ##  ####       ##
    #  ##     ## ##    ##    ##     ##  ##     ## ##   ### ##    ##
    #  ##     ##  ######     ##    ####  #######  ##    ##  ######

    # @!group Security Actions

    # Check if Discord has detected a raid in the guild.
    # @return [true, false] Whether or not Discord has detected a raid.
    def raid_detected?
      !@raid_detected_at.nil?
    end

    # Check if Discord has detected DM spam from the guild.
    # @return [true, false] Whether or not Discord has detected DM spam.
    def dm_spam_detected?
      !@dm_spam_detected_at.nil?
    end

    # Check if the guild has stopped members who aren't friends from DMing each other.
    # @return [true, false] Whether or not the guild has disabled non-friend direct messages.
    def dms_disabled?
      !@dms_disabled_until.nil? && @dms_disabled_until > Time.now
    end

    # Check if the guild has prevented new members from joining the guild, e.g. via invites.
    # @return [true, false] Whether or not invites have been disabled via incident actions or the
    #   `:INVITES_DISABLED` guild {#features feature}.
    def invites_disabled?
      return true if @features.include?(:INVITES_DISABLED)

      !@invites_disabled_until.nil? && @invites_disabled_until > Time.now
    end

    # @!endgroup

    #  ######## ######## ##     ## ########  ##          ###    ######## ########  ######
    #     ##    ##       ###   ### ##     ## ##         ## ##      ##    ##       ##    ##
    #     ##    ##       #### #### ##     ## ##        ##   ##     ##    ##       ##
    #     ##    ######   ## ### ## ########  ##       ##     ##    ##    ######    ######
    #     ##    ##       ##     ## ##        ##       #########    ##    ##             ##
    #     ##    ##       ##     ## ##        ##       ##     ##    ##    ##       ##    ##
    #     ##    ######## ##     ## ##        ######## ##     ##    ##    ########  ######

    # @!group Templates

    # Create a new template.
    # @param name [String] The 1-100 character name of the
    #   template.
    # @param description [String, nil] The 1-120 character
    #   description of the template.
    # @return [GuildTemplate] The template that was created.
    def create_template(name:, description: nil)
      data = {
        name: name,
        description: description
      }

      response = @bot.http.create_guild_template(@id, **data)
      GuildTemplate.new(response, @bot)
    end

    # Get a specific template on the guild.
    # @param code [#to_s, nil] The code of the template to get.
    # @return [GuildTemplate, nil] The template that was found, or `nil`.
    def template(code)
      if bot.can_manage_guild?
        templates.find { |template| template.code == code }
      else
        (template = @bot.guild_template(code.to_s)) if code

        template&.guild_id&.resolve_id == @id ? template : nil
      end
    end

    # Get the templates for the guild.
    # @return [Array<GuildTemplate>] The templates for the guild.
    def templates
      response = @bot.http.list_guild_templates(@id)
      response.map { |template| GuildTemplate.new(template, @bot) }
    end

    # @!endgroup

    #   ######   #######  ##     ## ##     ## ##     ## ##    ## #### ######## ##    ##
    #  ##    ## ##     ## ###   ### ###   ### ##     ## ###   ##  ##     ##     ##  ##
    #  ##       ##     ## #### #### #### #### ##     ## ####  ##  ##     ##      ####
    #  ##       ##     ## ## ### ## ## ### ## ##     ## ## ## ##  ##     ##       ##
    #  ##       ##     ## ##     ## ##     ## ##     ## ##  ####  ##     ##       ##
    #  ##    ## ##     ## ##     ## ##     ## ##     ## ##   ###  ##     ##       ##
    #   ######   #######  ##     ## ##     ##  #######  ##    ## ####    ##       ##

    # @!group Community Experience

    # Get the onboarding flow for the guild.
    # @return [Onboarding, nil] The onboarding flow for the guild.
    def onboarding
      response = @bot.http.get_guild_onboarding(@id)
      Onboarding.new(response, self, @bot)
    rescue Discordrb::Errors::NoPermission, Discordrb::Errors::NotFound
      nil
    end

    # Get the welcome screen for the guild.
    # @return [WelcomeScreen, nil] The welcome screen for the guild.
    def welcome_screen
      response = @bot.http.get_guild_welcome_screen(@id)
      WelcomeScreen.new(response, self, @bot)
    rescue Discordrb::Errors::NoPermission, Discordrb::Errors::NotFound
      nil
    end

    # @!endgroup

    #     ###     ##     ## ########  #### ########       ##        #######   ######
    #    ## ##    ##     ## ##     ##  ##     ##          ##       ##     ## ##    ##
    #   ##   ##   ##     ## ##     ##  ##     ##          ##       ##     ## ##
    #  ##     ##  ##     ## ##     ##  ##     ##          ##       ##     ## ##   ####
    #  #########  ##     ## ##     ##  ##     ##          ##       ##     ## ##    ##
    #  ##     ##  ##     ## ##     ##  ##     ##          ##       ##     ## ##    ##
    #  ##     ##   #######  ########  ####    ##          ########  #######   ######

    # @!group Audit Log

    # Get the audit log for the guild.
    # @param limit [Integer, nil] The maximum number of audit log entries to fetch,
    #   or `nil` to fetch all of the matching audit log entries.
    # @param user [User, Member, Integer, String] Filter entries by the user who performed them.
    # @param target [#resolve_id, Integer, String, nil] Filter entries by the entity it affects.
    # @param action [Integer, String, Symbol] Filter entries by the type of action that was done.
    # @param after [Time, #resolve_id, nil] Get audit log entries starting from after this point.
    # @param before [Time, #resolve_id, nil] Get audit log entries starting from before this point.
    # @param oldest_first [true, false, nil] Whether to return audit log entries in oldest to newest order.
    # @note When using the `after` or `oldest_first` parameters, entries will be sorted in ascending order
    #    by entry ID (oldest entries first), and in descending order by entry ID (newest entries first) otherwise.
    # @return [Array<AuditLog::Entry>] The audit log entries for the guild.
    def audit_log(
      limit: 50, user: nil, target: nil, action: nil, after: nil, before: nil,
      oldest_first: nil
    )
      if action && !action.is_a?(Integer)
        action = AuditLogs::ACTIONS[action.to_sym]
        raise ArgumentError, "Invalid value for the 'action' parameter" unless action
      end

      if [before, after, oldest_first].count(&:itself) > 1
        raise ArgumentError, "'before', 'after', and 'oldest_first' are mutually exclusive"
      end

      user = user&.resolve_id
      target = target&.resolve_id
      f_limit = limit && limit <= 100 ? limit : 100
      results = Hash.new { |hash, key| hash[key] = [] }
      f_after = after.is_a?(Time) ? Snowflake.synthesise(after) : after&.resolve_id
      f_before = before.is_a?(Time) ? Snowflake.synthesise(before) : before&.resolve_id

      # Reverses the list and starts fetching the oldest entries first, in ascending order.
      f_after = 0 if oldest_first

      fetch_audit_log = lambda do |before: nil, after: nil|
        data = @bot.http.get_guild_audit_log(@id,
                                             limit: f_limit,
                                             action_type: action,
                                             user_id: user,
                                             target_id: target,
                                             after: after || f_after,
                                             before: before || f_before)
        data.each do |key, value|
          results[key].concat(value) if key != :audit_log_entries && value.is_a?(Array)
        end

        data[:audit_log_entries]
      end

      paginator = Paginator.new(limit, :down) do |page|
        if f_after
          fetch_audit_log.call(after: page&.last&.[](:id))
        else
          fetch_audit_log.call(before: page&.last&.[](:id))
        end
      end

      entries = paginator.to_a
      results = AuditLog::Entities.new(results, self, @bot)
      entries.tap { |list| list.map! { |entry| AuditLog::Entry.new(entry, results, @bot) } }
    end

    alias_method :audit_logs, :audit_log

    # @!endgroup

    #  ####  ###   ## ######## ######## ########  ##    ##    ###    ##        ######
    #   ##   ###   ##    ##    ##       ##     ## ###   ##   ## ##   ##       ##    ##
    #   ##   ####  ##    ##    ##       ##     ## ####  ##  ##   ##  ##       ##
    #   ##   ## ## ##    ##    ######   ########  ## ## ## ##     ## ##        ######
    #   ##   ##  ####    ##    ##       ##   ##   ##  #### ######### ##             ##
    #   ##   ##   ###    ##    ##       ##    ##  ##   ### ##     ## ##       ##    ##
    #  ####  ##    ##    ##    ######## ##     ## ##    ## ##     ## ########  ######

    # @!visibility private
    def cache_role(role)
      @roles[role.id] = role
    end

    # @!visibility private
    def delete_member(user_id)
      @members.delete(user_id)
      @member_count -= 1 unless @member_count <= 0
    end

    # @!visibility private
    def cache_member(member, increment: nil)
      (@member_count += 1) if increment
      @members[member.id] = member
    end

    # @!visibility private
    def cache_scheduled_event(event)
      @scheduled_events[event.id] = event
    end

    # @!visibility private
    def delete_scheduled_event(event)
      @scheduled_events.delete(event.resolve_id)
    end

    # @!visibility private
    def cache_channel(channel)
      if channel.thread?
        @threads[channel.id] = channel
      else
        @channels[channel.id] = channel
      end
    end

    # @!visibility private
    def delete_channel(id, type = nil)
      if [10, 11, 12].include?(type)
        @threads.delete(id)
      else
        @channels.delete(id)
      end

      return unless [2, 13].include?(type)

      @voice_states.delete_if { |_, state| state.channel_id == id }
    end

    # @!visibility private
    def cache_emoji(emoji)
      @emojis[emoji.id] = emoji
    end

    # @!visibility private
    def delete_soundboard_sound(sound)
      @soundboard_sounds.delete(sound.resolve_id)
    end

    # @!visibility private
    def cache_soundboard_sound(sound)
      @soundboard_sounds[sound.resolve_id] = sound
    end

    # @!visibility private
    def cache_automod_rule(automod_rule)
      @automod_rules[automod_rule.id] = automod_rule
    end

    # @!visibility private
    def delete_automod_rule(automod_rule)
      @automod_rules.delete(automod_rule.resolve_id)
    end

    # @!visibility private
    def delete_sticker(sticker)
      @stickers.delete(sticker.resolve_id)
    end

    # @!visibility private
    def ensure_member(data, force_cache = true)
      if (member = @members[data[:user][:id].to_i])
        member.update_data(data) if force_cache
      else
        member = Member.new(data, self, @bot)
        cache_member(member)
      end

      member
    end

    # @!visibility private
    def delete_role(role_id)
      id = role_id.resolve_id
      @roles.delete(id)
      @members.each_value { |member| member.pop_role(id) }
      @channels.each_value { |channel| channel.pop_permission_overwrite(id) }
    end

    # @!visibility private
    def update_role_positions(roles, reason: nil)
      data = @bot.http.modify_guild_role_positions(@id, roles, reason: reason)
      data.each { |role_data| @roles[role_data[:id].to_i]&.update_data(role_data) }
    end

    # @!visibility private
    def clear_threads(ids = nil)
      ids ? @threads.delete_if { |_, item| ids.any?(item.parent_id) } : @threads = {}
    end

    # @!visibility private
    def process_chunk(members, chunk_index, chunk_count, nonce, not_found, presences)
      return (@member_chunk_queries[nonce] = { members:, not_found: }) if nonce && @member_chunk_queries.key?(nonce)

      process_members(members)
      process_presences(presences) if presences
      LOGGER.debug("Processed chunk #{chunk_index + 1}/#{chunk_count} guild #{@id} - index #{chunk_index} - length #{members.length}")

      return if chunk_index + 1 < chunk_count

      LOGGER.debug("Finished chunking guild #{@id}")

      # Reset everything to normal
      @chunked = true
    end

    # @!visibility private
    def update_voice_state(data)
      user_id = data[:user_id].to_i

      if data[:channel_id]
        if (state = @voice_states[user_id])
          state.update_data(data)
        else
          @voice_states[user_id] = VoiceState.new(data, @bot)
        end
      else
        # The user is not in a voice channel anymore, so delete its voice state.
        @voice_states.delete(user_id)
      end
    end

    # @!visibility private
    def inspect
      "<Guild id=#{@id} name=\"#{@name}\" owner_id=#{@owner_id}>"
    end

    # @!visibility private
    def update_data(new_data = nil)
      new_data ||= @bot.http.get_guild(@id)
      @name = new_data[:name]
      @icon = new_data[:icon]
      @splash = new_data[:splash]
      @discovery_splash = new_data[:discovery_splash]
      @owner_id = new_data[:owner_id].to_i

      @afk_timeout = new_data[:afk_timeout]
      @afk_channel_id = new_data[:afk_channel_id]&.to_i

      @widget_enabled = new_data[:widget_enabled] if new_data.key?(:widget_enabled)
      @widget_channel_id = new_data[:widget_channel_id] if new_data.key?(:widget_channel_id)

      @system_channel_flags = new_data[:system_channel_flags]
      @system_channel_id = new_data[:system_channel_id]&.to_i

      @rules_channel_id = new_data[:rules_channel_id]&.to_i
      @public_updates_channel_id = new_data[:public_updates_channel_id]&.to_i
      @safety_alerts_channel_id = new_data[:safety_alerts_channel_id]&.to_i

      @mfa_level = new_data[:mfa_level]
      @nsfw_level = new_data[:nsfw_level]
      @verification_level = new_data[:verification_level]
      @explicit_content_filter = new_data[:explicit_content_filter]
      @notification_level = new_data[:default_message_notifications]

      @features = new_data[:features]&.map(&:to_sym) || @features || []
      @max_presence_count = new_data[:max_presences] if new_data.key?(:max_presences)
      @max_member_count = new_data[:max_members] if new_data.key?(:max_members)
      @member_count = new_data[:member_count] || new_data[:approximate_member_count] || @member_count || 0
      @presence_count = new_data[:approximate_presence_count]

      @vanity_invite_code = new_data[:vanity_url_code]
      @description = new_data[:description]
      @banner = new_data[:banner]
      @premium_tier = new_data[:premium_tier]
      @premium_count = new_data[:premium_subscription_count] || @premium_count || 0
      @locale = new_data[:preferred_locale]

      @max_video_channel_members = new_data[:max_video_channel_users] || @max_video_channel_members
      @max_stage_video_channel_members = new_data[:max_stage_video_channel_users] || @max_stage_video_channel_members
      @premium_progress_bar = new_data[:premium_progress_bar_enabled]

      process_channels(new_data[:channels]) if new_data[:channels]
      process_roles(new_data[:roles]) if new_data[:roles]
      process_emojis(new_data[:emojis]) if new_data[:emojis]
      process_members(new_data[:members]) if new_data[:members]
      process_presences(new_data[:presences]) if new_data[:presences]
      process_voice_states(new_data[:voice_states]) if new_data[:voice_states]
      process_active_threads(new_data[:threads]) if new_data[:threads]
      process_incident_actions(new_data[:incidents_data]) if new_data.key?(:incidents_data)
      process_scheduled_events(new_data[:guild_scheduled_events]) if new_data[:guild_scheduled_events]
      process_stage_instances(new_data[:stage_instances]) if new_data[:stage_instances]
      process_soundboard_sounds(new_data[:soundboard_sounds]) if new_data[:soundboard_sounds]
      process_stickers(new_data[:stickers]) if new_data[:stickers]
    end

    private

    # @!visibility private
    def cache_widget(data = nil)
      return if !@widget_enabled.nil? && !data

      data ||= if bot.can_manage_guild?
                 @bot.http.get_guild_widget_settings(@id)
               else
                 return update_data(nil)
               end

      @widget_enabled = data[:enabled]
      @widget_channel_id = data[:channel_id]
    end

    def process_roles(roles)
      @roles = {}

      roles&.each do |element|
        role = Role.new(element, self, @bot)
        @roles[role.id] = role
      end
    end

    def process_emojis(emojis)
      @emojis = {}

      emojis&.each do |element|
        emoji = Emoji.new(element, @bot, self)
        @emojis[emoji.id] = emoji
      end
    end

    def process_members(members)
      members&.each do |element|
        member = Member.new(element, self, @bot)
        @members[member.id] = member
      end
    end

    def process_presences(presences)
      # Update user statuses with presence info
      presences&.each do |element|
        next unless (user = element[:user])

        @members[user[:id].to_i]&.user&.update_presence(element)
      end
    end

    def process_channels(channels)
      @channels = {}

      # Set this so we know the channels are cached.
      @resolved_channels = true

      channels&.each do |element|
        channel = @bot.ensure_channel(element, self)
        @channels[channel.id] = channel
      end
    end

    def process_voice_states(voice_states)
      voice_states&.each do |element|
        update_voice_state(element)
      end
    end

    def process_active_threads(threads)
      @threads ||= {}

      # Set this so we know the threads are cached.
      @resolved_threads = true

      threads&.each do |element|
        thread = @bot.ensure_channel(element, self)
        @threads[thread.id] = thread
      end
    end

    def process_incident_actions(incidents)
      incidents&.each do |key, value|
        case key
        when :raid_detected_at
          @raid_detected_at = value ? Time.iso8601(value) : value
        when :dms_disabled_until
          @dms_disabled_until = value ? Time.iso8601(value) : value
        when :dm_spam_detected_at
          @dm_spam_detected_at = value ? Time.iso8601(value) : value
        when :invites_disabled_until
          @invites_disabled_until = value ? Time.iso8601(value) : value
        end
      end
    end

    def process_scheduled_events(events)
      @scheduled_events = {}

      events&.each do |element|
        event = ScheduledEvent.new(element, self, @bot)
        @scheduled_events[event.id] = event
      end
    end

    def process_stage_instances(instances)
      instances&.each do |element|
        channel = @channels[element[:channel_id].to_i]
        channel&.process_stage_instance(element)
      end
    end

    def process_soundboard_sounds(sounds)
      @soundboard_sounds = {}

      sounds&.each do |element|
        sound = SoundboardSound.new(element, self, @bot)
        @soundboard_sounds[sound.id] = sound
      end
    end

    def process_stickers(stickers)
      @stickers = {}

      stickers&.each do |element|
        sticker = Sticker.new(element, self, @bot)
        @stickers[sticker.id] = sticker
      end
    end
  end

  # A ban entry on a guild.
  class GuildBan
    # @return [User] the user that was banned.
    attr_reader :user

    # @return [Guild] the guild that the user was banned from.
    attr_reader :guild

    # @return [String, nil] the reason for banning the user, if any.
    attr_reader :reason

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @reason = data[:reason]
      @user = @bot.ensure_user(data[:user])
    end

    # Remove the ban for the associated user in the guild.
    # @param reason [String, nil] the reason for removing the ban, if any.
    # @return [nil]
    def remove(reason: nil)
      @guild.unban(@user, reason:)
    end

    alias_method :lift, :remove
    alias_method :unban, :remove
  end

  # A bulk ban entry on a guild.
  class BulkBan
    # @return [Guild] The guild the bulk ban belongs to.
    attr_reader :guild

    # @return [String, nil] The reason these users were banned.
    attr_reader :reason

    # @return [Array<Integer>] Array of user IDs that were banned.
    attr_reader :banned_users

    # @return [Array<Integer>] Array of user IDs that couldn't be banned.
    attr_reader :failed_users

    # @!visibility private
    def initialize(data, guild, reason)
      @guild = guild
      @reason = reason
      @banned_users = data[:banned_users]&.map(&:resolve_id) || []
      @failed_users = data[:failed_users]&.map(&:resolve_id) || []
    end
  end

  # A set of messages collected from a search query.
  class SearchedMessages
    include Enumerable

    # @return [Array<Message>] the messages that matched the search query.
    attr_reader :messages

    # @return [Integer] the total number of messages that matched the search query.
    attr_reader :total_results

    # @!visibility private
    def initialize(messages, total, bot)
      @bot = bot
      @messages = messages
      @total_results = total
    end

    # Get a single message that matched the search query by its index.
    # @param index [Integer] The index of the message to get from the array.
    # @return [Message] the message that was found at the specified index.
    def [](index)
      @messages[index]
    end

    # Iterate over each message that matched the search query.
    # @return [Array<Message>, Enumerable] The array that was iterated over.
    def each(...)
      @messages.each(...)
    end

    # @!visibility private
    def inspect
      "<SearchedMessages messages=[#{'...' if @messages.any?}] total_results=#{@total_results}>"
    end
  end

  # A set of matching members.
  class QueriedMembers
    include Enumerable

    # @return [Guild] the guild the members were queried for.
    attr_reader :guild

    # @return [Array<Member>] the members that matched the query.
    attr_reader :members

    # @return [Array<Integer>] the invalid user IDs that were passed.
    attr_reader :not_found

    # @return [true, false] whether or not the gateway query timed-out.
    attr_reader :timed_out
    alias timed_out? timed_out

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @timed_out = data[:timeout] || false
      @not_found = data[:not_found]&.map(&:to_i) || []
      @members = data[:members]&.map { |item| @guild.ensure_member(item) } || []
    end

    # @!visibility private
    def each(...)
      @members.each(...)
    end

    # @!visibility private
    def inspect
      "<QueriedMembers members=[#{'...' if @members.any?}] timed_out=#{@timed_out}>"
    end
  end

  # A set of join requests collected from a query.
  class QueriedJoinRequests
    include Enumerable

    # @return [Array<JoinRequest>] the join requests that matched the query.
    attr_reader :join_requests

    # @return [Integer, nil] the total number of join requests that matched the query.
    # @note This will always be `nil` unless {Guild#join_requests} was queried with the
    #   `status:` argument set to `:submitted`.
    attr_reader :total_results

    # @!visibility private
    def initialize(join_requests, total, bot)
      @bot = bot
      @total_results = total
      @join_requests = join_requests
    end

    # Get a single join request that matched the query by its index.
    # @param index [Integer] The index of the join request to get from the array.
    # @return [JoinRequest] the join request that was found at the specified index.
    def [](index)
      @join_requests[index]
    end

    # Iterate over each join request that matched the query.
    # @return [Array<JoinRequest>, Enumerable] The array that was iterated over.
    def each(...)
      @join_requests.each(...)
    end

    # @!visibility private
    def inspect
      "<QueriedJoinRequests join_requests=[#{'...' if @join_requests.any?}]>"
    end
  end
end
