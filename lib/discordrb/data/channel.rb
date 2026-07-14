# frozen_string_literal: true

module Discordrb
  # A channel on Discord.
  class Channel
    include Snowflake

    # Mapping of types.
    TYPES = {
      text: 0,
      dm: 1,
      voice: 2,
      group_dm: 3,
      category: 4,
      announcement: 5,
      announcement_thread: 10,
      public_thread: 11,
      private_thread: 12,
      stage: 13,
      directory: 14,
      forum: 15,
      media: 16
    }.freeze

    # Mapping of layouts.
    LAYOUTS = {
      default: 0,
      list: 1,
      gallery: 2
    }.freeze

    # Mapping of sort orders.
    SORT_ORDERS = {
      recent_activity: 0,
      creation_time: 1
    }.freeze

    # Mapping of video qualities.
    VIDEO_QUALITIES = {
      automatic: 1,
      full: 2
    }.freeze

    # Mapping of flags.
    FLAGS = {
      pinned: 1 << 1,
      requires_tag: 1 << 4,
      hide_download_options: 1 << 15,
      obfuscated: 1 << 17,
      spoiler: 1 << 21
    }.freeze

    # @return [Integer] the type of the channel.
    attr_reader :type

    # @return [String, nil] the name of the channel, `nil` for obfuscated channels.
    attr_reader :name

    # @return [Integer] the flags for the channel represented as a bitfield.
    attr_reader :flags

    # @return [String, nil] the topic of the channel, dobules as the guidelines of a forum.
    attr_reader :topic

    # @return [true, false] whether or not the thread has been locked.
    attr_reader :locked

    # @return [Integer, nil] the bitrate (in bits) of the voice or stage channel.
    attr_reader :bitrate

    # @return [Integer, nil] the ID of the guild associated with the channel.
    attr_reader :guild_id

    # @return [Integer] the sorting position of the channel; not guranteed to be unique.
    attr_reader :position

    # @return [true, false] whether or not the thread has been archived.
    attr_reader :archived

    # @return [true, false] Whether or not non-moderators can add other non-moderators
    #   to the private thread.
    attr_reader :invitable

    # @return [Integer, nil] the ID of the category channel, or the thread's parent channel.
    attr_reader :parent_id

    # @return [User, nil] the user that the private channel is associated with.
    attr_reader :recipient

    # @return [Integer, nil] the user limit of the voice or stage channel; `0` for no limit.
    attr_reader :user_limit

    # @return [Time, nil] the time at when the thread was last archived or un-archived.
    attr_reader :archived_at

    # @return [String, nil] the RTC voice region of the voice channel; `nil` if automatic.
    attr_reader :voice_region

    # @return [Integer] the number of messages sent in the thread, excluding deleted messages.
    attr_reader :message_count

    # @return [Integer] the duration (in seconds) a user has to wait between sending messages.
    attr_reader :slowmode_rate

    # @return [Integer, nil] the ID of the most recently sent message, or the most recently created
    #   thread in a forum. May not reference a valid thread or message.
    attr_reader :last_entity_id

    # @return [Integer] the number of messages ever sent in the thread, including deleted messages.
    attr_reader :total_message_count

    # @return [Symbol, nil] the default tag matching algorithim to use when searching for threads in the forum.
    attr_reader :default_tag_matching

    # @return [Integer, nil] the duration after which the thread will automatically be hidden.
    attr_reader :auto_archive_duration

    # @return [Time, nil] the time at when the last pinned message was pinned.
    attr_reader :last_message_pinned_at

    # @return [Integer, nil] the default slowmode rate to copy onto newly-created threads in the channel.
    attr_reader :default_thread_slowmode_rate

    # @return [Integer, nil] the default auto archive duration to copy onto newly-created threads in the channel.
    attr_reader :default_auto_archive_duration

    alias_method :locked?, :locked
    alias_method :archived?, :archived
    alias_method :invitable?, :invitable

    # @!visibility private
    def initialize(data, bot, guild = nil)
      @bot = bot
      @guild = guild
      @id = data[:id].to_i
      @owner_id = data[:owner_id]&.to_i
      @guild_id = @guild&.id || data[:guild_id]&.to_i
      @recipient = @bot.ensure_user(data[:recipients][0]) if dm?
      update_data(data)

      return unless thread?

      @thread_members = {}

      if (member = data[:member])
        member[:id] = @id
        member[:user_id] = @bot.profile.id
        ensure_thread_member(member)
      end
    end

    #  ##     ##    ###    #### ##    ##
    #  ###   ###   ## ##    ##  ###   ##
    #  #### ####  ##   ##   ##  ####  ##
    #  ## ### ## ##     ##  ##  ## ## ##
    #  ##     ## #########  ##  ##  ####
    #  ##     ## ##     ##  ##  ##   ###
    #  ##     ## ##     ## #### ##    ##

    # @!group General

    # Get a string that will mention the channel.
    # @return [String] A string that will mention the channel.
    def mention
      "<##{@id}>"
    end

    # Get the time at when the channel was created.
    # @return [Time] The time at when the channel was created.
    #   Not accurate for threads created before January 9th, 2022.
    def creation_time
      @create_timestamp || super
    end

    # Check if the channel has been marked as age-restricted.
    # @return [true, false] Whether or not the channel is age-restricted.
    def nsfw?
      thread? ? parent.nsfw? : @nsfw
    end

    # Check if the channel is an orphan, meaning it isn't in a category.
    # @return [true, false] Whether or not the channel is an orphan channel.
    def orphan?
      category? == false && @parent_id.nil?
    end

    # Get the category the channel is under, or the thread's parent.
    # @return [Channel, nil] The category the channel is under, or the thread's parent.
    def parent
      @bot.channel(@parent_id) if @parent_id
    end

    # Get the guild the channel is associated with, if applicable.
    # @return [Guild, nil] The guild for the channel, or `nil` if the channel is a DM.
    def guild
      @guild ||= (@bot.guild(@guild_id) if @guild_id)
    end

    # Get a link that will navigate to the channel in the Discord client.
    # @return [String] A link that will navigate to the channel in the Discord client.
    def jump_link
      "https://discord.com/channels/#{@guild_id || '@me'}/#{@id}"
    end

    # Delete the channel. This cannot be undone for guild channels.
    # @param reason [String, nil] The reason to show in the audit log for deleting the channel.
    # @return [nil]
    def delete(reason: nil)
      update_data(@bot.http.delete_channel(@id, reason: reason))
      nil
    end

    # Get the members that can view the channel, or are connected to it.
    # @param connected [true, false, nil] When set to `true`, the members who are currently
    #   connected to the voice or stage channel will be returned instead.
    # @return [Array<Member>] The members who can view the channel, are connected to it, or
    #   the members who have joined the thread.
    def members(connected: true)
      return thread_members if thread?

      if connected && (voice? || stage?)
        guild.members.select { |member| member.voice_channel&.id == @id }
      else
        guild&.members&.select { |member| member.can_read_messages?(self) } || []
      end
    end

    # Change the position of the channel in the channels list.
    # @param above [Channel, Integer, String, nil] The channel to move this one above.
    # @param below [Channel, Integer, String, nil] The channel to move this one below.
    # @param orphan [true, nil] Whether to remove the channel from its current category.
    # @param sync_overwrites [true, false, nil] Whether to sync the overwrites of the channel
    #   with the new category channel (if moving to a new category).
    # @return [nil]
    def move(above: nil, below: nil, orphan: nil, sync_overwrites: nil)
      if [above, below, orphan].count(&:itself) > 1
        raise ArgumentError, "'above', 'below', and 'orphan' are mutually exclusive"
      end

      if !@guild_id || directory? || thread?
        raise TypeError, 'Unable to sort the current channel due to an invalid type'
      end

      if (above || below) && !(target = @bot.channel(above || below))
        raise ArgumentError, "The given 'above' or 'below' options are not valid"
      end

      if (above || below) && @guild_id != target.guild&.id
        raise ArgumentError, 'The target channel that was provded is not valid'
      end

      if !category? && (above && target&.category?)
        raise ArgumentError, 'The target channel that was provded is not valid'
      end

      if category? && (!target || !target.category?)
        raise ArgumentError, 'Categories must be sorted within the same bucket'
      end

      if category? && orphan
        raise ArgumentError, 'Categories cannot be orphaned'
      end

      list = if category? && target&.category?
               guild.categories
             elsif orphan
               guild.orphan_channels
             elsif target&.category?
               target.children
             else
               target.parent.children
             end

      list.sort_by! { |item| [item.bucket, item.position, item.id] }

      list.rindex(self)&.tap { |index| list.delete_at(index) }

      if !category? && target&.category?
        list.insert(0, self)
      elsif orphan
        list.insert(-1, self)
      elsif above
        list.insert(list.rindex(target), self)
      elsif below
        list.insert(list.rindex(target) + 1, self)
      end

      unless list.length <= 1 || category? || target&.category? || orphan
        hash = {}
        current_bucket = nil

        list.each do |channel|
          next unless channel.bucket != current_bucket

          if hash[channel.bucket]
            raise ArgumentError, 'The target channel that was provded is not valid'
          end

          hash[current_bucket] = true if current_bucket
          current_bucket = channel.bucket
        end
      end

      list.map!.with_index do |channel, index|
        hash = { id: channel.id, position: index }

        if channel.id == @id
          hash[:parent_id] = if category? || orphan || target&.orphan?
                               nil
                             elsif !category? && target&.category?
                               target.id
                             else
                               target.parent_id
                             end

          (hash[:lock_permissions] = sync_overwrites) unless category?
        end

        hash
      end

      @bot.http.modify_guild_channel_positions(@guild_id, list)
      nil
    end

    # Modify the properties of the channel.
    # @param name [String] The new 1-100 character name of the channel.
    # @param type [Integer, Symbol] The new type of the channel. You can only convert between text and announcement channels.
    # @param topic [String, nil] The 0-1024 character topic of the channel; 0-4096 characters for forum channels.
    # @param nsfw [true, false, nil] Whether or not the channel should be marked as age-restricted.
    # @param slowmode_rate [Integer, nil] The new slowmode-rate of the channel; between 0-21600 (in seconds).
    # @param bitrate [Integer, nil] The new bitrate of the voice or stage channel; minimum of 8000 (in bits).
    # @param overwrites [Array<Overwrite, #to_h>, nil] The new permission overwrites to set for the channel.
    # @param user_limit [Integer, nil] The maximum number of users who can join the voice or stage channel; 0 for no limit.
    # @param parent [Channel, Integer, String, nil] The new category channel to set, or `nil` to orphan the chnanel.
    # @param voice_region [VoiceRegion, String, nil] The new voice region to set for the voice or stage channel.
    # @param video_quality_mode [Symbol, Integer, nil] The new camera video quality mode to set for the voice or stage channel.
    # @param default_auto_archive_duration [Integer, nil] The default client-side duration before a thread is archived due to inactivity.
    # @param flags [Symbol, Integer, Array<Symbol, Integer>] The flags to set for the channel.
    # @param tags [Array<ChannelTag, #to_h, #resolve_id>] The tags to set on the thread channel, or the new tags that will be available in the forum channel.
    # @param default_reaction [Integer, String, Emoji, nil] The emoji to display on threads created in the forum channel.
    # @param default_sort_order [Integer, Symbol, nil] The default order used to order threads in the forum channel.
    # @param default_layout [Integer, Symbol] The default layout type used to display threads in the forum channel.
    # @param archived [true, false] Whether or not the thread should be archived.
    # @param locked [true, false] Whether or not the thread should be locked.
    # @param invitable [true, false] Whether or not non-moderators should be able to add other non-moderators to the private thread.
    # @param auto_archive_duration [Integer] The amount of minutes after which the thread will stop showing in the channel list.
    # @param position [Integer, nil] The new sorting position of the channel. Usage of this parameter is highly discouraged. Please use {#move} instead.
    # @param add_flags [Symbol, Integer, Array<Symbol, Integer>] The flags to add to the channel. Mutually exclusive with `flags:`.
    # @param remove_flags [Symbol, Integer, Array<Symbol, Integer>] The flags to remove from the channel. Mutually exclusive with `flags:`.
    # @param default_thread_slowmode_rate [Integer] The default slowmode rate to set on threads created in the text or forum channel.
    # @param status [String, nil] The status to set for the voice channel; between 1-500 characters, or `nil` to clear the existing status.
    # @param reason [String, nil] The reason to show in the guild's audit log for modifying the channel.
    # @return [nil]
    def modify(
      name: :undef, type: :undef, topic: :undef, nsfw: :undef, slowmode_rate: :undef, bitrate: :undef,
      overwrites: :undef, user_limit: :undef, parent: :undef, voice_region: :undef, video_quality_mode: :undef,
      default_auto_archive_duration: :undef, flags: :undef, tags: :undef, default_reaction: :undef, default_sort_order: :undef,
      default_layout: :undef, archived: :undef, locked: :undef, invitable: :undef, auto_archive_duration: :undef, position: :undef,
      add_flags: :undef, remove_flags: :undef, default_thread_slowmode_rate: :undef, status: :undef, reason: nil
    )
      data = {
        name: name,
        type: TYPES[type] || type,
        topic: topic,
        nsfw: nsfw,
        position: position,
        rate_limit_per_user: slowmode_rate,
        bitrate: bitrate,
        user_limit: user_limit,
        parent_id: parent == :undef ? parent : parent&.resolve_id,
        rtc_region: voice_region == :undef ? voice_region : voice_region&.to_s,
        video_quality_mode: VIDEO_QUALITIES[video_quality_mode] || video_quality_mode,
        permission_overwrites: overwrites == :undef ? overwrites : [*overwrites].map(&:to_h),
        default_auto_archive_duration: default_auto_archive_duration,
        default_reaction_emoji: default_reaction == :undef ? default_reaction : Emoji.build_hash(default_reaction),
        default_sort_order: SORT_ORDERS[default_sort_order] || default_sort_order,
        default_forum_layout: LAYOUTS[default_layout] || default_layout,
        archived: archived,
        flags: flags == :undef ? flags : [*flags].reduce(0) { |sum, bit| sum | (FLAGS[bit] || bit.to_i) },
        default_thread_rate_limit_per_user: default_thread_slowmode_rate,
        auto_archive_duration: auto_archive_duration,
        locked: locked,
        invitable: invitable
      }

      if tags != :undef && ((forum? || media?) || thread?)
        tags = (thread? ? tags&.map(&:resolve_id)&.uniq : tags&.map(&:to_h))

        data[thread? ? :applied_tags : :available_tags] = tags
      end

      if data[:type] != :undef
        if announcement? && data[:type] != TYPES[:announcement]
          raise ArgumentError, 'Can only convert news channels to text channels'
        elsif text? && data[:type] != TYPES[:announcement]
          raise ArgumentError, 'Can only convert text channels to news channels'
        elsif !text? && !announcement?
          raise ArgumentError, 'Can only convert between text and news channels'
        end
      end

      if add_flags != :undef || remove_flags != :undef
        raise ArgumentError, "'add_flags' and 'remove_flags' cannot be used with 'flags'" if flags != :undef

        to_flags = lambda do |bits|
          bits == :undef ? 0 : [*bits].reduce(0) { |sum, bit| sum | (FLAGS[bit] || bit.to_i) }
        end

        data[:flags] = ((@flags & ~to_flags.call(remove_flags)) | to_flags.call(add_flags))
      end

      if status != :undef && voice?
        @bot.http.set_voice_channel_status(@id, status: status.to_s, reason: reason)

        return unless data.any? { |_, value| value != :undef }
      end

      update_data(@bot.http.modify_channel(@id, **data, reason: reason))
      nil
    end

    alias_method :category, :parent
    alias_method :jump_url, :jump_link

    # @!endgroup

    #  ######## ##    ## ########  ########  ######
    #     ##     ##  ##  ##     ## ##       ##    ##
    #     ##      ####   ##     ## ##       ##
    #     ##       ##    ########  ######    ######
    #     ##       ##    ##        ##             ##
    #     ##       ##    ##        ##       ##    ##
    #     ##       ##    ##        ########  ######

    # @!group Types

    # Check if the channel is a private channel.
    # @return [true, false] Whether or not the channel is a DM or group DM channel.
    def private?
      dm? || group_dm?
    end

    # Check if the channel is a thread channel; regardless of its specific sub-type.
    # @return [true, false] Whether or not the channel is any of the three thread types.
    def thread?
      announcement_thread? || public_thread? || private_thread?
    end

    # @!method text?
    #   @return [true, false] whether or not the channel is a text channel within a guild.
    # @!method dm?
    #   @return [true, false] whether or not the channel is a private channel between two users.
    # @!method voice?
    #   @return [true, false] whether or not the channel is a voice channel within a guild.
    # @!method group_dm?
    #   @return [true, false] whether or not the channel is a private channel between multiple users.
    # @!method category?
    #   @return [true, false] whether or not the channel is an organizational category within a guild.
    # @!method announcement?
    #   @return [true, false] whether or not the channel is a news channel, allowing members to {#follow follow} it.
    # @!method announcement_thread?
    #   @return [true, false] whether or not the channel is a thread created from a message in an announcement channel.
    # @!method public_thread?
    #   @return [true, false] whether or not the channel is a thread viewable by anyone with permissions.
    # @!method private_thread?
    #   @return [true, false] whether or not the channel is a thread only viewable by invited members.
    # @!method stage?
    #   @return [true, false] whether or not the channel is a voice channel used for hosting events within a guild.
    # @!method directory?
    #   @return [true, false] whether or not the channel is the main channel in a student hub.
    # @!method forum?
    #   @return [true, false] whether or not the channel is a thread-only channel within a guild.
    # @!method media?
    #   @return [true, false] whether or not the channel is a thread-only channel that only supports gallery view.
    TYPES.each do |name, value|
      define_method("#{name}?") { @type == value }
    end

    # @!endgroup

    #  ######## ##          ###     ######    ######
    #  ##       ##         ## ##   ##    ##  ##    ##
    #  ##       ##        ##   ##  ##        ##
    #  ######   ##       ##     ## ##   ####  ######
    #  ##       ##       ######### ##    ##        ##
    #  ##       ##       ##     ## ##    ##  ##    ##
    #  ##       ######## ##     ##  ######    ######

    # @!group Flags

    # @!method pinned?
    #   @return [true, false] whether or not the thread has been pinned in its parent channel.
    # @!method requires_tag?
    #   @return [true, false] whether or not a tag must be applied to any threads created in the channel.
    # @!method hide_download_options?
    #   @return [true, false] whether or not the download options are hidden in the media channel.
    # @!method obfuscated?
    #   @return [true, false] whether or not the bot can't view the channel and its info has been hidden.
    # @!method spoiler?
    #   @return [true, false] whether or not the channel may contain spoilers or sensitive discussions.
    FLAGS.each do |name, value|
      if name == :spoiler
        define_method("#{name}?") { !nsfw? && (@flags.anybits?(value) || parent&.spoiler? || false) }
      else
        define_method("#{name}?") { @flags.anybits?(value) }
      end
    end

    # @!endgroup

    #  ########  ######## ########  ##     ## ####  ######   ######  ####  #######  ##    ##  ######
    #  ##     ## ##       ##     ## ###   ###  ##  ##    ## ##    ##  ##  ##     ## ###   ## ##    ##
    #  ##     ## ##       ##     ## #### ####  ##  ##       ##        ##  ##     ## ####  ## ##
    #  ########  ######   ########  ## ### ##  ##   ######   ######   ##  ##     ## ## ## ##  ######
    #  ##        ##       ##   ##   ##     ##  ##        ##       ##  ##  ##     ## ##  ####       ##
    #  ##        ##       ##    ##  ##     ##  ##  ##    ## ##    ##  ##  ##     ## ##   ### ##    ##
    #  ##        ######## ##     ## ##     ## ####  ######   ######  ####  #######  ##    ##  ######

    # @!group Overwrites

    # Get a single permission overwrite for the channel by ID.
    # @param target [#resolve_id] The ID of the permission overwrite to retrieve.
    # @return [Overwrite, nil] The permission overwrite for the given ID or `nil`.
    def overwrite(target)
      obfuscated? ? nil : @overwrites[target&.resolve_id]
    end

    # Get the explicit permission overwrites for members and roles.
    # @param type [Symbol, Integer, nil] The specific type of overwrites to return.
    # @return [Array<Overwrite>] The explicit permission overwrites for the channel.
    def overwrites(type: nil)
      return [] if obfuscated?

      case type
      when nil, :all
        @overwrites.values
      when Overwrite::TYPES[:role], :role
        @overwrites.filter_map { |_, value| value if value.role? }
      when Overwrite::TYPES[:member], :member, :user
        @overwrites.filter_map { |_, value| value if value.member? }
      else
        raise ArgumentError, "The value for the 'type' argument is invalid"
      end
    end

    # Modify the permissions for a specific overwrite.
    # @param denied [Permissions, Integer, nil] The permissisons that should be denied.
    # @param allowed [Permissions, Integer, nil] The permissisons that should be allowed.
    # @param role [Role, Integer, String, nil] The role that the overwrite should target.
    # @param member [User, Member, Integer, String, nil] The member that the overwrite should target.
    # @param reason [String, nil] The reason to show in the guild's audit log for modifying the overwrite.
    # @return [nil]
    def modify_overwrite(
      allowed: :undef, denied: :undef, user: nil, role: nil,
      member: nil, reason: nil
    )
      if [role, user, member].count(&:itself) != 1
        raise ArgumentError, "'role', 'user', and 'member' are mutually exclusive"
      end

      id = (user || member)&.resolve_id || role.resolve_id
      old = overwrite(id)

      data = {
        deny: (denied == :undef ? old&.denied : denied)&.to_i&.to_s,
        allow: (allowed == :undef ? old&.allowed : allowed)&.to_i&.to_s,
        type: role ? Overwrite::TYPES[:role] : Overwrite::TYPES[:member]
      }

      @bot.http.modify_channel_permissions(@id, id, **data, reason: reason)
      nil
    end

    # Delete a specific permission overwrite.
    # @param target [Integer, String, Role, User, Member] The ID of the overwrite to delete.
    # @param reason [String, nil] The reason to show in the audit log for deleting the overwrite.
    # @return [nil]
    def delete_overwrite(target, reason: nil)
      @bot.http.delete_channel_permissions(@id, target.resolve_id, reason: reason)
      nil
    end

    # @!endgroup

    #  ##     ## ########  ######   ######     ###     ######   ########  ######
    #  ###   ### ##       ##    ## ##    ##   ## ##   ##    ##  ##       ##    ##
    #  #### #### ##       ##       ##        ##   ##  ##        ##       ##
    #  ## ### ## ######    ######   ######  ##     ## ##   #### ######    ######
    #  ##     ## ##             ##       ## ######### ##    ##  ##             ##
    #  ##     ## ##       ##    ## ##    ## ##     ## ##    ##  ##       ##    ##
    #  ##     ## ########  ######   ######  ##     ##  ######   ########  ######

    # @!group Messages

    # Start typing in the channel.
    # @return [nil]
    def begin_typing
      @bot.http.trigger_typing_indicator(@id)
      nil
    end

    # Get a single message by its ID.
    # @param id [Integer, String, Message] the ID of the message to retrieve.
    # @return [Message, nil] The message that was retrieved, or `nil` if it doesn't exist.
    def message(id)
      Message.new(@bot.http.get_channel_message(@id, id.resolve_id), @bot)
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Get the most recently sent message in the channel.
    # @return [Message, nil] The most recently sent message, or `nil` if it couldn't be found.
    # @note This method uses the {#last_entity_id} method. For a more reliable way of fetching
    #   the latest message, please consider using the {#messages} method instead.
    def last_message
      message(@last_entity_id) if @last_entity_id && !(forum? || media?)
    end

    # Get the messages that have been pinned in the channel.
    # @param limit [Integer, nil] The maximum number of pins to retrieve, or `nil` to retrieve all the pins.
    # @return [Array<Message>] The messages that have been pinned, ordered in descending order by {Message#pinned_at}.
    def pins(limit: 50)
      get_pins = proc do |fetch_limit, before = nil|
        response = @bot.http.list_channel_pins(@id, limit: fetch_limit, before: before&.iso8601)
        response[:items].map { |pin| Message.new(pin[:message].merge!(pinned_at: pin[:pinned_at]), @bot) }
      end

      paginator = Paginator.new(limit, :down) do |last_page|
        if last_page && last_page.count < 50
          []
        else
          get_pins.call(50, last_page&.last&.pinned_at)
        end
      end

      paginator.to_a
    end

    # Get the messages that have been sent in the channel.
    # @param limit [Integer, nil] The maximum number of messages to fetch, or `nil` to retrieve all the messages.
    # @param after [Message, Integer, String, Time, nil] Get messages that were sent after this snowflake ID.
    # @param before [Message, Integer, String, Time, nil] Get messages that were sent before this snowflake ID.
    # @param around [Message, Integer, String, Time, nil] Get messages that were sent around this snowflake ID.
    # @param oldest_first [true, false] Whether the oldest messages in the channel should be fetched first.
    # @return [Array<Message>] The messages that were fetched. By default, messages will be returned in descending order by
    #   message ID (newest messages first). On the contrary, when using the `after:` or `oldest_first:` parameters, messages
    #   will be returned in ascending order by message ID (oldest messages first).
    def messages(limit: 100, after: nil, before: nil, around: nil, oldest_first: false)
      if [before, after, around, oldest_first].count(&:itself) > 1
        raise ArgumentError, "'before', 'after', 'around', and 'oldest_first' are mutually exclusive"
      end

      if around && (!limit || limit > 100)
        raise ArgumentError, "You cannot fetch more than 100 messages when using the 'around' parameter"
      end

      after = 0 if oldest_first

      rest = {
        limit: limit && limit <= 100 ? limit : 100,
        after: after.is_a?(Time) ? Snowflake.synthesise(after) : after&.resolve_id,
        before: before.is_a?(Time) ? Snowflake.synthesise(before) : before&.resolve_id,
        around: around.is_a?(Time) ? Snowflake.synthesise(around) : around&.resolve_id
      }.compact

      get_messages = proc do |query = nil|
        response = @bot.http.list_channel_messages(@id, **rest, **query&.compact)
        response.map { |message_data| Message.new(message_data, @bot) }
      end

      return get_messages.call if around

      paginator = Paginator.new(limit, after ? :up : :down) do |page|
        if after
          get_messages.call(after: page&.first&.id)
        else
          get_messages.call(before: page&.last&.id)
        end
      end

      paginator.to_a
    end

    # Send a message in the channel.
    # @example This sends a silent message with an embed.
    #   channel.send_message(content: 'Hi <@171764626755813376>', flags: :suppress_notifications) do |builder|
    #     builder.add_embed do |embed|
    #       embed.title = 'The Ruby logo'
    #       embed.image = 'https://www.ruby-lang.org/images/header-ruby-logo.png'
    #     end
    #   end
    # @param content [String, nil] The content of the message. Should not be longer than 2000 characters or it will result in an error.
    # @param timeout [Float, nil] The amount of time in seconds after which the message sent will be deleted, or `nil` if the message should not be deleted.
    # @param tts [true, false] Whether or not this message should be sent using Discord text-to-speech.
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds that should be attached to the message.
    # @param attachments [Array<File>] Files that can be referenced in embeds and components via `attachment://file.png`.
    # @param allowed_mentions [Hash, Discordrb::AllowedMentions, nil] Mentions that are allowed to ping on this message.
    # @param reference [Message, String, Integer, Hash, nil] The optional message, or message ID, to reply to or forward.
    # @param components [View, Array<#to_h>] Interaction components to associate with this message.
    # @param flags [Integer, Symbol, Array<Symbol, Integer>] Flags for this message. Currently only `:suppress_embeds` (1 << 2), `:suppress_notifications` (1 << 12), and `:uikit_components` (1 << 15) can be set.
    # @param has_components [true, false] Whether this message includes any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param nonce [nil, String, Integer, false] The 25 character nonce that should be used when sending this message.
    # @param enforce_nonce [true, false] Whether the provided nonce should be enforced and used for message de-duplication.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to the message.
    # @param stickers [Array<Integer, String, Sticker>, Integer, String, Sticker, nil] The stickers that should be sent with the message.
    # @param client_theme [hash, ClientTheme::Builder, ClientTheme, nil] The client-side theme to share via the message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the builder overwrite method data.
    # @yieldparam view [Webhooks::View] An optional component builder. Arguments passed to the builder overwrite method data.
    # @return [Message] The message that was created.
    def send_message(content: nil, timeout: nil, tts: false, embeds: [], attachments: nil, allowed_mentions: nil, reference: nil, components: nil, flags: 0, has_components: false, nonce: nil, enforce_nonce: false, poll: nil, stickers: nil, client_theme: nil)
      view = Discordrb::Webhooks::View.new
      builder = Discordrb::Webhooks::Builder.new

      builder.tts = tts
      builder.poll = poll
      builder.content = content
      builder.client_theme = client_theme
      embeds&.each { |embed| builder << embed }
      builder.allowed_mentions = allowed_mentions

      yield(builder, view) if block_given?

      flags = [*flags].reduce(0) { |sum, bit| sum | (Discordrb::Message::FLAGS[bit] || bit.to_i) }
      flags |= Discordrb::Message::FLAGS[:uikit_components] if has_components
      builder = builder.to_json_hash

      if timeout
        @bot.send_temporary_message(timeout, @id, builder[:content], builder[:tts], builder[:embeds], attachments, builder[:allowed_mentions], reference, components&.to_a || view.to_a, flags, nonce, enforce_nonce, builder[:poll], stickers, builder[:shared_client_theme])
      else
        @bot.send_message(@id, builder[:content], builder[:tts], builder[:embeds], attachments, builder[:allowed_mentions], reference, components&.to_a || view.to_a, flags, nonce, enforce_nonce, builder[:poll], stickers, builder[:shared_client_theme])
      end
    end

    # Delete multiple messages that were sent within the last 14 days.
    # @param messages [Array<Message, Integer, String>] the messages that should be deleted.
    # @param reason [String, nil] The reason to show in the audit log for deleting the messages.
    # @return [nil]
    def delete_messages(messages, reason: nil)
      unless (messages = [*messages].map(&:resolve_id)).length.between?(0, 100)
        raise ArgumentError, "The 'messages' array must be 1-100 elements in length"
      end

      return if messages.empty?

      # If we're only deleting one message, don't bother.
      if messages.length > 1
        minimum_id = Snowflake.synthesise(Time.now - 1_209_600)

        messages.reject! { |message_id| message_id < minimum_id }
      end

      if messages.one?
        begin
          @bot.http.delete_message(@id, messages[0])
        rescue Discordrb::Errors::NotFound
          return nil
        end
      elsif messages.any?
        @bot.http.bulk_delete_messages(@id, messages: messages, reason: reason)
      end

      nil
    end

    # Delete multiple messages from the channel's history.
    # @param limit [Integer, nil] The number of messages to fetch.
    # @param after [Integer, Time, nil] Get messages starting from after this ID.
    # @param before [Integer, Time, nil] Get messages starting from before this ID.
    # @param around [Integer, Time, nil] Get messages starting from around this ID.
    # @param oldest_first [true, false, nil] Whether to fetch the oldest messages first.
    # @param one_for_one [true, false, nil] Whether every message should be deleted individually.
    # @param reason [String, nil] The reason to show in the audit log for bulk-deleting the messages.
    # @yield [Message] Yields each message that was fetched in order to filter the messages to delete.
    # @return [Array<Message>] The messages that were selected for deletion.
    def purge_messages(
      limit:, after: nil, before: nil, around: nil, oldest_first: nil,
      one_for_one: false, reason: nil, &
    )
      messages = messages(limit:, after:, before:, around:, oldest_first:)
      messages.select!(&) if block_given?

      if one_for_one
        messages.each do |message|
          message.delete
        rescue Discordrb::Errors::NotFound
          next
        rescue Discordrb::Errors::BadRequest => e
          e.code == 50_021 ? next : raise(e)
        end
      else
        messages.each_slice(100) do |chunk|
          minimum_id = Snowflake.synthesise(Time.now - 1_209_600)

          old, now = chunk.partition { |message| message.id < minimum_id }

          if now.one?
            begin
              now[0].delete
            rescue Discordrb::Errors::NotFound
              nil
            rescue Discordrb::Errors::BadRequest => e
              raise(e) unless e.code == 50_021
            end
          elsif now.any?
            now.map!(&:resolve_id)
            @bot.http.bulk_delete_messages(@id, messages: now, reason: reason)
          end

          old.each do |message|
            message.delete
          rescue Discordrb::Errors::NotFound
            next
          rescue Discordrb::Errors::BadRequest => e
            e.code == 50_021 ? next : raise(e)
          end
        end
      end

      messages
    end

    # Add a blocking {Await} for a message in this channel. This is identical in functionality to
    #   adding a {Discordrb::Events::MessageEvent} await with the `in` attribute as this channel.
    # @see Bot#add_await!
    def await!(attributes = {}, &block)
      @bot.add_await!(Discordrb::Events::MessageEvent, { in: @id }.merge(attributes), &block)
    end

    # Add an {Await} for a message in this channel. This is identical in functionality to adding a
    #   {Discordrb::Events::MessageEvent} await with the `in` attribute as this channel.
    # @see Bot#add_await
    def await(key, attributes = {}, &block)
      @bot.add_await(key, Discordrb::Events::MessageEvent, { in: @id }.merge(attributes), &block)
    end

    # @!endgroup

    #  ##     ##  #######  ####  ######  ########
    #  ##     ## ##     ##  ##  ##    ## ##
    #  ##     ## ##     ##  ##  ##       ##
    #  ##     ## ##     ##  ##  ##       ######
    #   ##   ##  ##     ##  ##  ##       ##
    #    ## ##   ##     ##  ##  ##    ## ##
    #     ###     #######  ####  ######  ########

    # @!group Voice Channels

    # Retrieve the video quality mode of the voice channel.
    # @return [Symbol, nil] The video quality of the voice channel.
    # @see VIDEO_QUALITIES
    def video_quality_mode
      VIDEO_QUALITIES.key(@video_quality_mode)
    end

    # Retrieve the status of the voice channel.
    # @return [String, nil] The status of the voice channel, or `nil`.
    def status
      if !instance_variable_defined?(:@status) && voice?
        @bot.gateway.request_channel_info(guild: @guild_id, fields: %i[status voice_start_time])

        sleep(0.01) until instance_variable_defined?(:@status)
      end

      @status
    end

    # Retrieve the start time of the sesison for the voice channel.
    # @return [Time, nil] The time at when the voice session started, or `nil`.
    def start_time
      if !instance_variable_defined?(:@start_time) && voice?
        @bot.gateway.request_channel_info(guild: @guild_id, fields: %i[status voice_start_time])

        sleep(0.01) until instance_variable_defined?(:@start_time)
      end

      @start_time
    end

    # Get the scheduled events for the voice or stage channel.
    # @return [Array<ScheduledEvent>] The scheduled events for the voice or stage channel.
    def scheduled_events
      guild&.scheduled_events&.select { |event| event.channel&.id == @id } || []
    end

    # @!endgroup

    #  ########  #######  ########  ##     ## ###     ###
    #  ##       ##     ## ##     ## ##     ## ####   ####
    #  ##       ##     ## ##     ## ##     ## ## ## ## ##
    #  ######   ##     ## ########  ##     ## ##  ###  ##
    #  ##       ##     ## ##   ##   ##     ## ##       ##
    #  ##       ##     ## ##    ##  ##     ## ##       ##
    #  ##        #######  ##     ##  #######  ##       ##

    # @!group Forum Channels

    # Retrieve the default layout of the forum channel.
    # @return [Symbol, nil] the default layout of the forum channel.
    # @see LAYOUTS
    def default_layout
      LAYOUTS.key(@default_layout)
    end

    # Retrieve the default sort order of the forum channel.
    # @return [Symbol, nil] The default sort order of the forum channel.
    # @see SORT_ORDERS
    def default_sort_order
      SORT_ORDERS.key(@default_sort_order)
    end

    # Retrieve a tag in the forum channel.
    # @param tag_id [Integer, String, ChannelTag] The ID of the tag to retrieve.
    # @return [ChannelTag, nil] The tag that was retrieved, or `nil` if not found.
    def tag(tag_id)
      tag_id = tag_id&.resolve_id

      @available_tags&.find { |tag| tag.id == tag_id }
    end

    # Retrieve the tags for the channel.
    # @return [Array<ChannelTag>] The available tags in the forum channel, or the
    #   tags that have been applied to the thread.
    def tags
      return (@available_tags&.dup || []) if forum? || media?

      @applied_tags&.filter_map { |id| parent.tag(id) } || []
    end

    # Create a new tag in the forum channel.
    # @param name [String] the 1-20 character name of the tag.
    # @param moderated [true, false] Whether the tag should be moderated.
    # @param emoji [Integer, String, Emoji, nil] The emoji to set for the tag.
    # @param reason [String, nil] The reason to show in the audit log for creating the tag.
    # @return [nil]
    def create_tag(name:, moderated:, emoji: nil, reason: nil)
      new_data = {
        name: name,
        moderated: moderated,
        **(emoji ? Emoji.build_hash(emoji) : {})
      }

      update_forum_tags(new_data, reason) if forum? || media?
    end

    # Get the default reaction shown on threads in the forum channel.
    # @return [Emoji, nil] The default reaction emoji of the forum channel.
    def default_reaction
      @default_reaction.is_a?(Integer) ? guild.emoji(@default_reaction) : @default_reaction
    end

    # Start a thread in the forum channel.
    # @param name [String] The name of the forum post to create.
    # @param auto_archive_duration [Integer, nil] How long before the post is automatically archived.
    # @param slowmode_rate [Integer, nil] The slowmode rate of the forum post to create.
    # @param tags [Array<#resolve_id>, nil] The tags of the forum channel to apply onto the forum post.
    # @param content [String, nil] The content of the forum post's starter message.
    # @param embeds [Array<Hash, Webhooks::Embed>, nil] The embeds that should be attached to the forum post's starter message.
    # @param allowed_mentions [Hash, Discordrb::AllowedMentions, nil] Mentions that are allowed to ping on this forum post's starter message.
    # @param components [Webhooks::View, Array<#to_h>, nil] The interaction components to associate with this forum post's starter message.
    # @param attachments [Array<File>, nil] Files that can be referenced in embeds and components via `attachment://file.png`.
    # @param flags [Integer, Symbol, Array<Symbol, Integer>, nil] The flags to set on the forum post's starter message. Currently only `:suppress_embeds` (1 << 2), `:suppress_notifications` (1 << 12), and `:uikit_components` (1 << 15) can be set.
    # @param stickers [Array<Integer, String, Sticker>, Integer, String, Sticker, nil] The stickers that should be sent with the forum post's starter message.
    # @param has_components [true, false] Whether the starter message for this forum post includes any V2 components. Enabling this disables sending content and embeds.
    # @param reason [String, nil] The reason to show in the guild's audit log for creating the forum post.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the builder overwrite method data.
    # @yieldparam view [Webhooks::View] An optional component builder. Arguments passed to the builder overwrite method data.
    # @return [Message] the starter message of the forum post. The forum post that was created can be accessed via {Message#thread}.
    def start_forum_thread(name:, auto_archive_duration: nil, slowmode_rate: nil, tags: nil, content: nil, embeds: nil, allowed_mentions: nil, components: nil, attachments: nil, flags: nil, stickers: nil, has_components: false, reason: nil)
      builder = Discordrb::Webhooks::Builder.new
      view = Discordrb::Webhooks::View.new

      builder.content = content
      embeds&.each { |embed| builder << embed }
      builder.allowed_mentions = allowed_mentions

      yield(builder, view) if block_given?

      flags = [*(flags || 0)].reduce(0) { |sum, bit| sum | (Discordrb::Message::FLAGS[bit] || bit.to_i) }
      (flags |= Discordrb::Message::FLAGS[:uikit_components]) if has_components
      builder = builder.to_json_hash

      data = {
        name: name,
        attachments: attachments,
        rate_limit_per_user: slowmode_rate,
        auto_archive_duration: auto_archive_duration,
        applied_tags: tags && tags != [] ? [*tags].map(&:resolve_id) : nil,
        message: {
          content: builder[:content],
          embeds: builder[:embeds],
          allowed_mentions: builder[:allowed_mentions],
          components: components&.to_a || view.to_a,
          sticker_ids: stickers ? [*stickers].map(&:resolve_id) : nil,
          flags: flags
        }.compact
      }

      response = @bot.http.start_thread_without_message(@id, **data.compact, reason: reason)
      Message.new(response[:message].merge!(channel_id: response[:id], thread: response), @bot)
    end

    alias_method :create_forum_post, :start_forum_thread
    alias_method :create_forum_thread, :start_forum_thread

    # @!endgroup

    #  ######## ##     ## ########  ########    ###    ########
    #     ##    ##     ## ##     ## ##         ## ##   ##     ##
    #     ##    ##     ## ##     ## ##        ##   ##  ##     ##
    #     ##    ######### ########  ######   ##     ## ##     ##
    #     ##    ##     ## ##   ##   ##       ######### ##     ##
    #     ##    ##     ## ##    ##  ##       ##     ## ##     ##
    #     ##    ##     ## ##     ## ######## ##     ## ########

    # @!group Thread Channels

    # Join the thread.
    # @return [nil]
    def join_thread
      @bot.http.join_thread(@id) if thread?
      nil
    end

    # Leave the thread.
    # @return [nil]
    def leave_thread
      @bot.http.leave_thread(@id) if thread?
      nil
    end

    # Retrieve a member in the thread.
    # @param user_id [Member, User, Integer, String] The ID of the thread member to retrieve.
    # @return [ThreadMember, nil] The thread member for the given ID, or `nil`.
    def thread_member(user_id)
      return nil unless thread?

      user_id = user_id.resolve_id

      stale = if user_id == @bot.profile.id
                @bot.gateway.intents.nobits?(INTENTS[:guilds])
              else
                @bot.gateway.intents.nobits?(INTENTS[:guild_members])
              end

      cached = @thread_members[user_id]
      return cached if cached && !stale

      begin
        data = @bot.http.get_thread_member(@id, user_id, with_member: true)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      ensure_thread_member(data)
    end

    # Add a member to the thread.
    # @param user_id [Member, User, Integer, String] The ID of the member to add to the thread.
    # @return [nil]
    def add_thread_member(user_id)
      @bot.http.add_thread_member(@id, user_id.resolve_id) if thread?
      nil
    end

    # Remove a member from the thread.
    # @param user_id [Member, User, Integer, String] The ID of the member to remove from the thread.
    # @return [nil]
    def remove_thread_member(user_id)
      @bot.http.remove_thread_member(@id, user_id.resolve_id) if thread?
      nil
    end

    # Retrieve the members that have joined the thread.
    # @return [Array<ThreadMember>] The members that have joined the thread.
    # @raise [Discordrb::Errors::NoPermission] If the bot hasn't enabled the `GUILD_MEMBERS` intent.
    def thread_members
      return [] unless thread?

      if @has_thread_members && @bot.gateway.intents.anybits?(INTENTS[:guild_members])
        return @thread_members&.values || []
      end

      get_members = lambda do |before = nil|
        list = @bot.http.list_thread_members(@id, before: before, limit: 100, with_member: true)
        list.tap { list.map! { |thread_member_data| ensure_thread_member(thread_member_data) } }
      end

      paginator = Paginator.new(nil, :down) do |last_page|
        if last_page && last_page.count < 100
          []
        else
          get_members.call(last_page&.last&.user_id)
        end
      end

      paginator.to_a.tap { @has_thread_members = true }
    end

    # Get the starter message of the thread.
    # @return [Message, nil] The starter message of the thread.
    def starter_message
      message(@id) if thread?
    end

    # Get the user who initially started the thread.
    # @return [User, nil] The user who initially started the thread.
    def owner
      @bot.user(@owner_id) if @owner_id
    end

    # Check if a tag is applied to the thread.
    # @param tag [ChannelTag, Integer, String] The tag that should be checked.
    # @return [true, false] Whether or not the tag has been applied to the thread.
    # @see #tags
    def tag?(tag)
      @applied_tags&.include?(tag&.resolve_id) || false
    end

    # Add a set of tags to the thread.
    # @param tags [Array<ChannelTag, Integer, String>, #resolve_id] The tags to apply to the thread.
    # @param reason [String, nil] The reason to show in the audit log for adding the tags to the thread.
    # @return [nil]
    def add_tags(tags, reason: nil)
      return unless thread? && (parent.forum? || parent.media?)

      modify(tags: (@applied_tags || []) + [*tags].map(&:resolve_id), reason: reason)
    end

    # Remove a set of tags from the thread.
    # @param tags [Array<ChannelTag, Integer, String>, #resolve_id] The tags to remove from the thread.
    # @param reason [String, nil] The reason to show in the audit log for removing the tags from the thread.
    # @return [nil]
    def remove_tags(tags, reason: nil)
      return unless thread? && (parent.forum? || parent.media?)

      modify(tags: (@applied_tags || []) - [*tags].map(&:resolve_id), reason: reason)
    end

    # Start a thread in the channel.
    # @param name [String] The 1-100 character name of the thread.
    # @param message [Message, Integer, String, nil] The message to reference when starting the thread.
    # @param type [Symbol, Integer, nil] The type of thread to create. Not required when `message:` is passed.
    # @param slowmode_rate [Integer, nil] the duration (in seconds) a member has to wait between sending messages.
    # @param auto_archive_duration [Integer, nil] the duration after which the thread will automatically be hidden.
    #   The only values that are valid for this argument are: `60`, `1440`, `4320`, `10080`.
    # @param reason [String, nil] The reason to show in the guild's audit log for creating the thread.
    # @return [Channel] The thread that was created.
    def start_thread(name:, type: nil, message: nil, slowmode_rate: nil, auto_archive_duration: nil, reason: nil)
      new_data = {
        name: name,
        rate_limit_per_user: slowmode_rate,
        type: message ? nil : (TYPES[type] || type),
        auto_archive_duration: auto_archive_duration
      }.compact

      response = if (message = message&.resolve_id)
                   @bot.http.start_thread_from_message(@id, message, **new_data, reason: reason)
                 else
                   @bot.http.start_thread_without_message(@id, **new_data, reason: reason)
                 end

      @bot.ensure_channel(response, @guild)
    end

    alias_method :add_tag, :add_tags
    alias_method :remove_tag, :remove_tags

    # @!endgroup

    #   ######  ########    ###     ######   ########
    #  ##    ##    ##      ## ##   ##    ##  ##
    #  ##          ##     ##   ##  ##        ##
    #   ######     ##    ##     ## ##   #### ######
    #        ##    ##    ######### ##    ##  ##
    #  ##    ##    ##    ##     ## ##    ##  ##
    #   ######     ##    ##     ##  ######   ########

    # @!group Stage Channels

    # Retrieve the stage instance for the stage channel.
    # @param request [true, false, nil] Whether to request the stage
    #   instance from Discord if it isn't already cached.
    # @return [StageInstance, nil] The stage instance associated with
    #   the stage channel, or `nil` if one doesn't exist.
    def stage_instance(request: false)
      return unless stage?

      intent = @bot.gateway.intents.anybits?(INTENTS[:guilds])

      return @stage_instance if intent && (@stage_instance || !request)

      process_stage_instance(@bot.http.get_stage_instance(@id))
    rescue Discordrb::Errors::NotFound
      nil
    end

    # Create a stage instance for the stage channel.
    # @param topic [String] The 1-120 character topic of the stage instance.
    # @param mention_everyone [true, false] Whether to mention `@everyone` when the stage instance starts.
    # @param scheduled_event [ScheduledEvent, Integer, String, nil] The scheduled event of the stage instance.
    # @param reason [String, nil] The reason to show in the guilds's audit log for creating the stage instance.
    # @return [StageInstance] The stage instance that was successfully created.
    def create_stage_instance(
      topic:, mention_everyone:, scheduled_event: nil, reason: nil
    )
      data = {
        topic: topic,
        reason: reason,
        channel_id: @id,
        send_start_notification: mention_everyone || false,
        guild_scheduled_event_id: scheduled_event&.resolve_id || :undef
      }

      process_stage_instance(@bot.http.create_stage_instance(**data))
    end

    # Retrieve the moderators of the stage channel.
    # @return [Array<Member>] The moderators of the stage channel.
    def stage_moderators
      return [] unless stage?

      bits = Permissions.bits(%i[manage_channels mute_members move_members])

      guild.members.select { |member| member.permissions(self).allbits?(bits) }
    end

    # @!endgroup

    #   ######     ###    ######## ########  #######   #######  ########  ##    ##
    #  ##    ##   ## ##      ##    ##       ##     ## ##     ## ##     ##  ##  ##
    #  ##        ##   ##     ##    ##       ##        ##     ## ##     ##   ####
    #  ##       ##     ##    ##    ######   ##   #### ##     ## ########     ##
    #  ##       #########    ##    ##       ##    ##  ##     ## ##   ##      ##
    #  ##    ## ##     ##    ##    ##       ##    ##  ##     ## ##    ##     ##
    #   ######  ##     ##    ##    ########  ######    #######  ##     ##    ##

    # @!group Category Channels

    # Get the channels within the category.
    # @return [Array<Channel>] The channels contained within the category.
    def children
      category? ? guild.channels.select { |value| value.parent_id == @id } : []
    end

    # @!endgroup

    #     ###     ##    ## ##    ##  #######  ##     ## ##    ##  ######  ######## ##     ## ######## ##    ## ########
    #    ## ##    ###   ## ###   ## ##     ## ##     ## ###   ## ##    ## ##       ###   ### ##       ###   ##    ##
    #   ##   ##   ####  ## ####  ## ##     ## ##     ## ####  ## ##       ##       #### #### ##       ####  ##    ##
    #  ##     ##  ## ## ## ## ## ## ##     ## ##     ## ## ## ## ##       ######   ## ### ## ######   ## ## ##    ##
    #  #########  ##  #### ##  #### ##     ## ##     ## ##  #### ##       ##       ##     ## ##       ##  ####    ##
    #  ##     ##  ##   ### ##   ### ##     ## ##     ## ##   ### ##    ## ##       ##     ## ##       ##   ###    ##
    #  ##     ##  ##    ## ##    ##  #######   #######  ##    ##  ######  ######## ##     ## ######## ##    ##    ##

    # @!group announcement Channels

    # Follow the announcement channel.
    # @param target [Integer, String, Channel] The channel to send crossposted message to.
    # @param reason [String, nil] The reason to show in the audit log for creating the follower webhook.
    # @return [Integer] The ID of the follower webhook that was created in the target channel.
    def follow(target, reason: nil)
      @bot.http.follow_announcement_channel(@id, webhook_channel_id: target.resolve_id, reason: reason)[:webhook_id].to_i
    end

    # @!endgroup

    #  ##          ## ######## ########  ##     ##  #######   #######  ##    ##  ######
    #  ##          ## ##       ##     ## ##     ## ##     ## ##     ## ##   ##  ##    ##
    #  ##          ## ##       ##     ## ##     ## ##     ## ##     ## ##  ##   ##
    #  ##    ##    ## ######   ########  ######### ##     ## ##     ## #####     ######
    #   ##  ####  ##  ##       ##     ## ##     ## ##     ## ##     ## ##  ##         ##
    #    ####  ####   ##       ##     ## ##     ## ##     ## ##     ## ##   ##  ##    ##
    #     ##    ##    ######## ########  ##     ##  #######   #######  ##    ##  ######

    # @!group Webhooks

    # Retrieve the webhooks for the channel.
    # @return [Array<Webhook>] The webhooks for the channel.
    def webhooks
      response = @bot.http.list_channel_webhooks(@id)
      response.map { |webhook| Webhook.new(webhook, @bot) }
    end

    # Create a webhook (an easy way to send messages) for the channel.
    # @param name [String] The default name of the webhook; 1-80 characters.
    # @param avatar [File, #read, nil] The default avatar image of the webhook.
    # @param reason [String, nil] The audit log reason for creating the webhook.
    # @return [Webhook] The webhook that was created.
    def create_webhook(name:, avatar: nil, reason: nil)
      avatar = Discordrb.encode64(avatar) if avatar.respond_to?(:read)

      response = @bot.http.create_webhook(@id, name:, avatar:, reason:)
      Webhook.new(response, @bot)
    end

    # @!endgroup

    #  #### ##    ## ##     ## #### ######## ########  ######
    #   ##  ###   ## ##     ##  ##     ##    ##       ##    ##
    #   ##  ####  ## ##     ##  ##     ##    ##       ##
    #   ##  ## ## ## ##     ##  ##     ##    ######    ######
    #   ##  ##  ####  ##   ##   ##     ##    ##             ##
    #   ##  ##   ###   ## ##    ##     ##    ##       ##    ##
    #  #### ##    ##    ###    ####    ##    ########  ######

    # @!group Invites

    # Retrieve the invites for the channel.
    # @return [Array<Invite>] The invites for the channel.
    def invites
      response = @bot.http.list_channel_invites(@id)
      response.map { |invite| Invite.new(invite, true, @bot) }
    end

    # Create an invite for the channel.
    # @param duration [Integer, nil] How long the invite should last before expring (in seconds).
    # @param max_uses [Integer, nil] The number of ttimes the invite can be used before expiring.
    # @param temporary [true, false] Whether or not the invite should only grant temporary membership.
    # @param unique [true, false] Whether or not the API should attempt to generate a unique invite code.
    # @param stream_user [User, Member, Integer, String, nil] The member whose "Go Live" stream should be shown.
    # @param embedded_application [Application, Integer, String, nil] The embedded application to open for the invite.
    # @param roles [Array<Role, Integer, String>, nil] The roles that should be granted to users who accept the invite.
    # @param target_users [Array<User, Member, Integer, String>, nil] The users that are allowed to accept the invite.
    # @param reason [String, nil] The reason to show in the guild's audit log for creating the invite.
    # @return [Invite, nil] The invite that was created, or `nil` if Discord's safety team has disabled invites for the guild.
    # @raise [ArgumentError] If `stream_user` and `embedded_application` are passed in conjunction with each other.
    def create_invite(
      duration: 86_400, max_uses: 0, temporary: false, unique: false, stream_user: nil,
      embedded_application: nil, roles: nil, flags: nil, target_users: nil, reason: nil
    )
      if target_users
        users = [*target_users].tap { |ids| ids.map!(&:resolve_id) }
        target_users = StringIO.new(users.join("\n"), 'rb')
      end

      if stream_user && embedded_application
        raise ArgumentError, "'stream_user' and 'embedded_application' are mutually exclusive"
      elsif stream_user || embedded_application
        target_type = stream_user ? 1 : 2
      end

      data = {
        unique: unique,
        max_uses: max_uses,
        temporary: temporary,
        max_age: duration || 0,
        target_users_file: target_users,
        target_type: target_type || nil,
        target_user_id: stream_user&.resolve_id,
        role_ids: ([*roles].map(&:resolve_id) if roles),
        target_application_id: embedded_application&.resolve_id,
        flags: flags
      }

      response = @bot.http.create_channel_invite(@id, **data.compact, reason: reason)
      response ? Invite.new(response, true, @bot) : nil
    end

    # @!endgroup

    #  ####  ###   ## ######## ######## ########  ##    ##    ###    ##        ######
    #   ##   ###   ##    ##    ##       ##     ## ###   ##   ## ##   ##       ##    ##
    #   ##   ####  ##    ##    ##       ##     ## ####  ##  ##   ##  ##       ##
    #   ##   ## ## ##    ##    ######   ########  ## ## ## ##     ## ##        ######
    #   ##   ##  ####    ##    ##       ##   ##   ##  #### ######### ##             ##
    #   ##   ##   ###    ##    ##       ##    ##  ##   ### ##     ## ##       ##    ##
    #  ####  ##    ##    ##    ######## ##     ## ##    ## ##     ## ########  ######

    # @!visibility private
    def update_data(new_data)
      @type = new_data[:type]
      @flags = new_data[:flags] || 0
      @name = obfuscated? ? nil : new_data[:name]
      @topic = new_data[:topic] == '' ? nil : new_data[:topic]
      @bitrate = new_data[:bitrate]
      @position = new_data[:position] || 0

      @parent_id = new_data[:parent_id]&.to_i
      @user_limit = new_data[:user_limit]
      @message_count = new_data[:message_count] || 0
      @voice_region = new_data[:rtc_region]
      @slowmode_rate = new_data[:rate_limit_per_user] || 0

      @last_entity_id = new_data[:last_message_id]&.to_i
      @total_message_count = new_data[:total_message_sent] || 0
      @default_tag_matching = new_data[:default_tag_setting]&.to_sym

      metadata = new_data[:thread_metadata]
      @locked = metadata&.[](:locked) || false
      @archived = metadata&.[](:archived) || false
      @invitable = metadata&.[](:invitable) || false
      @archived_at = Time.iso8601(metadata[:archive_timestamp]) if metadata&.[](:archive_timestamp)
      @create_timestamp ||= Time.iso8601(metadata[:create_timestamp]) if metadata&.[](:create_timestamp)
      @auto_archive_duration = metadata&.[](:auto_archive_duration)

      @nsfw = new_data[:nsfw] || false
      @default_layout = new_data[:default_forum_layout]
      @default_sort_order = new_data[:default_sort_order]
      @video_quality_mode = new_data[:video_quality_mode]
      @applied_tags = new_data[:applied_tags]&.map(&:to_i)

      process_available_tags(new_data[:available_tags])
      process_last_pin_timestamp(new_data[:last_pin_timestamp])
      process_permission_overwrites(new_data[:permission_overwrites])
      process_default_reaction_emoji(new_data[:default_reaction_emoji])
    end

    # @!visibility private
    def process_last_entity_id(last_id)
      @last_entity_id = last_id
    end

    # @!visibility private
    def pop_permission_overwrite(id)
      @overwrites.delete(id.resolve_id)
    end

    # @!visibility private
    def process_status(status)
      @status = (status == '' ? nil : status)
    end

    # @!visibility private
    def bucket
      (voice? || stage? ? 2 : 1) unless private?
    end

    # @!visibility private
    def process_start_time(time)
      @start_time = (time ? Time.at(time) : nil)
    end

    # @!visibility private
    def pop_thread_member(user_id)
      @thread_members&.delete(user_id.resolve_id)
    end

    # @!visibility private
    def ensure_thread_member(data)
      guild&.ensure_member(data[:member]) if data[:member]

      if (member = @thread_members[data[:user_id]&.to_i])
        member.update_data(data)
        member
      else
        thread_member = ThreadMember.new(data, self, @bot)
        @thread_members[thread_member.user_id] = thread_member
      end
    end

    # @!visibility private
    def process_stage_instance(instance)
      return (@stage_instance = nil) unless instance

      @stage_instance = StageInstance.new(instance, self, @bot)
    end

    # @!visibility private
    def process_last_pin_timestamp(time)
      @last_message_pinned_at = time ? Time.iso8601(time) : time
    end

    # @!visibility private
    def update_forum_tags(tag, reason)
      tags = @available_tags.dup.tap { |old| old.delete(tag[:id]) }

      modify(tags: (tag[:_d] ? tags : (tags << tag)), reason: reason)
    end

    # @!visibility private
    def inspect
      "<Channel id=#{@id} type=#{@type} guild_id=#{@guild_id || 'nil'}>"
    end

    private

    # @!visibility private
    def process_permission_overwrites(array)
      @overwrites = {}

      array&.each do |item|
        overwrite = Overwrite.new(item, self, @bot)
        @overwrites[overwrite.resolve_id] = overwrite
      end
    end

    # @!visibility private
    def process_default_reaction_emoji(emoji)
      return (@default_reaction = nil) unless emoji&.any?

      @default_reaction = if (name = emoji[:emoji_name])
                            Emoji.new({ name: name }, @bot)
                          else
                            emoji[:emoji_id]&.to_i
                          end
    end

    # @!visibility private
    def process_available_tags(array)
      return unless array

      if @available_tags&.any?
        old = @available_tags

        @available_tags = array.map do |tag|
          id = tag[:id].to_i
          current = old.find { |key| key.id == id }
          current&.update_data(tag)
          current || ChannelTag.new(tag, self, @bot)
        end
      else
        @available_tags = array.map { |tag| ChannelTag.new(tag, self, @bot) }
      end
    end
  end
end
