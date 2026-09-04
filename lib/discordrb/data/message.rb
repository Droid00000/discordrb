# frozen_string_literal: true

module Discordrb
  # A message that was sent in a channel.
  class Message
    include Snowflake

    # Mapping of flags.
    FLAGS = {
      crossposted: 1 << 0,
      crosspost: 1 << 1,
      suppress_embeds: 1 << 2,
      source_message_deleted: 1 << 3,
      urgent: 1 << 4,
      thread: 1 << 5,
      ephemeral: 1 << 6,
      loading: 1 << 7,
      failed_to_mention_roles: 1 << 8,
      suppress_notifications: 1 << 12,
      voice_message: 1 << 13,
      snapshot: 1 << 14,
      uikit_components: 1 << 15
    }.freeze

    # Mapping of types.
    TYPES = {
      default: 0,
      thread_member_add: 1,
      thread_member_remove: 2,
      call: 3,
      channel_name_change: 4,
      channel_pinned_message: 6,
      guild_member_join: 7,
      premium_guild_subscription: 8,
      guild_premium_tier_one: 9,
      guild_premium_tier_two: 10,
      guild_premium_tier_three: 11,
      channel_follow_add: 12,
      guild_discovery_disqualified: 14,
      guild_discovery_requalified: 15,
      guild_discovery_grace_period_initial_warning: 16,
      guild_discovery_grace_period_final_warning: 17,
      thread_created: 18,
      reply: 19,
      chat_input_command: 20,
      thread_starter_message: 21,
      guild_invite_reminder: 22,
      context_menu_command: 23,
      automod_action: 24,
      role_subscription_purchase: 25,
      interaction_premium_upsell: 26,
      stage_start: 27,
      stage_end: 28,
      stage_speaker: 29,
      stage_raise_hand: 30,
      stage_topic: 31,
      guild_application_premium_subscription: 32,
      guild_incident_alert_mode_enabled: 36,
      guild_incident_alert_mode_disabled: 37,
      guild_incident_report_raid: 38,
      guild_incident_report_false_alarm: 39,
      purchase_notification: 44,
      poll_result: 46
    }.freeze

    # @return [Integer] the type of the message.
    attr_reader :type

    # @return [Integer] the flags for the message.
    attr_reader :flags

    # @return [String, nil] the nonce sent with the message.
    attr_reader :nonce

    # @return [String] the text-content of the message.
    attr_reader :content

    # @return [Array<User>] the users mentioned via the message.
    attr_reader :mentions

    # @return [Time, nil] the time at when the message was edited.
    attr_reader :edited_at

    # @return [Array<Attachment>] the files attached to the message.
    attr_reader :attachments

    # @return [Array<Embed>] the embeds attached to the message.
    attr_reader :embeds

    # @return [Array<Reaction>] the emoji reactions for the message.
    # @note Messages that were retrieved via {Channel#pins}, {Guild#search_messages},
    #   and {Events::ApplicationCommandEvent#target} will always return an empty array
    #   for this attribute, even if the message has reactions.
    attr_reader :reactions

    # @return [Integer, nil] the ID of the webhook that sent the message.
    attr_reader :webhook_id

    # @return [Integer, nil] the ID of the application associated with the interaction.
    attr_reader :application_id

    # @return [MessageActivity, nil] the rich-presence activity attached to the message.
    attr_reader :activity

    # @return [Array<Snapshot>] the immutable copies of the messages that were forwarded.
    attr_reader :snapshots

    # @return [MessageReference, nil] the information about the message that was referenced.
    attr_reader :reference

    # @return [Interactions::Metadata, nil] the information about the interaction for the message.
    attr_reader :interaction_metadata

    # @return [Channel, nil] the thread that was started from the message.
    attr_reader :thread

    # @return [Array<Sticker::Item>] the stickers that are attached to the message.
    attr_reader :stickers

    # @return [Integer] the position of the message in the thread. Always `0` for non-thread messages.
    attr_reader :position

    # @return [Array<Component>] the bot components that were sent with the message.
    attr_reader :components

    # @return [Poll, nil] the poll attached to the message.
    attr_reader :poll

    # @return [PollResult, nil] the finalized poll results that prompted the message.
    attr_reader :poll_results
    alias poll_result poll_results

    # @return [Call, nil] the call that prompted the message.
    attr_reader :call

    # @return [Time, nil] the time at when the message was pinned in the channel.
    # @note This will only be present for messages that were retrieved via the {Channel#pins} method.
    attr_reader :pinned_at

    # @return [ClientTheme, nil] the custom client-theme shared through the message.
    attr_reader :client_theme

    # @return [RoleSubscription, nil] the role subscription purchase or renewal that prompted the message.
    attr_reader :role_subscription

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @type = data[:type]
      @flags = data[:flags] || 0
      @nonce = data[:nonce]
      @channel_id = data[:channel_id].to_i
      @content = data[:content]
      @mentions = data[:mentions]&.map { |item| @bot.ensure_user(item) } || []
      @webhook_id = data[:webhook_id]&.to_i
      @application_id = data[:application_id]&.to_i
      @position = data[:position] || 0

      @tts = data[:tts]
      @pinned = data[:pinned]
      @mentions_everyone = data[:mention_everyone]
      @mention_roles = data[:mention_roles]&.map(&:to_i)

      @pinned_at = Time.iso8601(data[:pinned_at]) if data[:pinned_at]
      @edited_at = Time.iso8601(data[:edit_timestamp]) if data[:edit_timestamp]

      @embeds = data[:embeds]&.map { |item| Embed.new(item, @bot) } || []
      @reactions = data[:reactions]&.map { |item| Reaction.new(item, self, @bot) } || []
      @attachments = data[:attachments]&.map { |item| Attachment.new(item, self, @bot) } || []
      @snapshots = data[:message_snapshots]&.map { |item| Snapshot.new(item[:message], @bot) } || []

      @thread = @bot.ensure_channel(data[:thread]) if data[:thread]
      @stickers = (data[:sticker_items] || data[:stickers])&.map { |item| Sticker::Item.new(item, @bot) } || []
      @components = data[:components]&.filter_map { |item| Components.from_data(item, @bot) } || []

      @call = Call.new(data[:call], @bot) if data[:call]
      @poll = Poll.new(data[:poll], self, @bot) if data[:poll]
      @activity = MessageActivity.new(data[:activity], @bot) if data[:activity]
      @client_theme = ClientTheme.new(data[:shared_client_theme], @bot) if data[:shared_client_theme]
      @poll_results = Poll::Result.new(data[:embeds].pop, data[:message_reference], @bot) if poll_result?

      if data[:author]
        if @webhook_id
          # Create a fake user for webhooks.
          data[:author][:_webhook] = true
          @author = User.new(data[:author], @bot)
        else
          # Cache the user for private channels.
          @bot.ensure_user(data[:author])
          @author_id = data[:author][:id].resolve_id
        end
      end

      if (reference = data[:message_reference])
        if data.key?(:referenced_message)
          reference[:message] = data[:referenced_message]
        end

        @reference = MessageReference.new(reference, @bot)
      end

      role_data = data[:role_subscription_data]
      @role_subscription = RoleSubscriptionData.new(role_data, self, @bot) if role_data

      interaction = data[:interaction_metadata]
      @interaction_metadata = Interactions::Metadata.new(interaction, self, @bot) if interaction
    end

    # @!attribute [r] tts?
    #   @return [true, false] whether or not the message will be read aloud when sent.
    # @!attribute [r] pinned?
    #   @return [true, false] whether or not the message has been pinned in the channel.
    # @!attribute [r] mentions_everyone?
    #   @return [true, false] whether or not the message pinged `@everyone` in the guild.
    %i[tts pinned mentions_everyone].each do |name|
      define_method("#{name}?") { instance_variable_get("@#{name}") }
    end

    #  ##     ##    ###    #### ##    ##
    #  ###   ###   ## ##    ##  ###   ##
    #  #### ####  ##   ##   ##  ####  ##
    #  ## ### ## ##     ##  ##  ## ## ##
    #  ##     ## #########  ##  ##  ####
    #  ##     ## ##     ##  ##  ##   ###
    #  ##     ## ##     ## #### ##    ##

    # @!group General

    # Delete the message. This is permanent.
    # @return [nil]
    def delete
      @bot.http.delete_message(@channel_id, @id)
      nil
    end

    # Get the that channel the message was sent in.
    # @return [Channel] The channel that the message was sent in.
    def channel
      @channel ||= @bot.channel(@channel_id)
    end

    # Get the that guild the message was sent in.
    # @return [Guild, nil] The guild that the message was sent in.
    def guild
      channel.guild
    end

    # Check whether the message has been modified.
    # @return [true, false] Whether or not the message has been edited.
    def edited?
      !@edited_at.nil?
    end

    # Check if a specific user or role was mentioned in the message.
    # @param target [User, Role, Member, Integer, String] The target to check.
    # @return [true, false] Whether or not the entity was mentioned in the message.
    def mentions?(target)
      entity = target.resolve_id

      # rubocop:disable Style/SoleNestedConditional
      return @mentions_everyone if channel.guild_id == entity

      if target.is_a?(Discordrb::Member)
        return true if @mentions_roles&.any? { |id| target.role?(id) }
      end

      # rubocop:enable Style/SoleNestedConditional
      @mentions.any?(entity) || @mentions_roles&.any?(entity) || false
    end

    # Get the roles that were mentioned via the message.
    # @return [Array<Role>] The roles that were mentioned via the message.
    def role_mentions
      return [] unless @mention_roles&.any?

      @role_mentions ||= @mention_roles.filter_map { |item| guild&.role(item) }
    end

    # Get the games that were mentioned in the message.
    # @return [Array<Integer>] The game IDs that were used in the message.
    def games
      return (@games || []) if @games || !@content || @content.empty?

      list = []

      @content.scan(/<@\$(\d{15,48})>/) { |(game)| list << game.to_i }

      @games = list
    end

    # Get the custom emojis that were used in the message.
    # @return [Array<Emoji>] The custom emojis that were used in the message.
    def emojis
      return (@emojis || []) if @emojis || !@content || @content.empty?

      list = []

      @content.scan(/<(a?):(\w{2,32}):(\d{15,48})>/) do |type, name, id|
        id = id.to_i
        animated = (type == 'a')
        list << (@bot.emoji(id) || Emoji.new({ id:, name:, animated: }, @bot))
      end

      @emojis = list
    end

    # Get the formatted timestamps contained in the message content.
    # @return [Array<TimestampMarkdown>] The formatted timestamps in the message.
    def timestamps
      return (@timestamps || []) if @timestamps || !@content || @content.empty?

      list = []

      @content.scan(/<t:(-?\d{1,13})(?::(t|T|d|D|f|F|s|S|R))?>/) do |time, specifier|
        # If it's not between these values, Discord won't show it, so don't even bother.
        if (time = time.to_i).between?(-8_640_000_000_000, 8_640_000_000_000)
          list << TimestampMarkdown.new(Time.at(time), specifier)
        end
      end

      @timestamps = list
    end

    # Get a URL that will navigate to the message in the Discord client when clicked.
    # @return [String] A link that will navigate to the message in the Discord client.
    def jump_link
      "https://discord.com/channels/#{channel.guild_id || '@me'}/#{@channel_id}/#{@id}"
    end

    # Modify the properties of the message.
    # @param content [String, nil] The content of the message. Should not be longer than 2000 characters or it will result in an error.
    # @param embeds [Array<Hash, Webhooks::EmbedBuilder>, nil] The embeds that should be attached to the message.
    # @param attachments [Array<File, Attachment, #read>, nil] The files that can be referenced in embeds and components via `attachment://file.png`.
    # @param allowed_mentions [Hash, Discordrb::AllowedMentions, nil] The mentions that are allowed to ping on the message.
    # @param flags [Integer, Symbol, Array<Symbol, Integer>] The new flags to set for the message.
    # @param components [View, Array<#to_h>, nil] The bot components to associate with the message.
    # @param add_flags [Symbol, Integer, Array<Symbol, Integer>] The flags to add to the message. Mutually exclusive with `flags:`.
    # @param remove_flags [Symbol, Integer, Array<Symbol, Integer>] The flags to remove from the message. Mutually exclusive with `flags:`.
    # @param has_components [true] Whether or not the message will include any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param crosspost [true] Whether or not the message should be published if it was sent in an announcement channel.
    # @param pinned [true, false] Whether or not the message should be pinned in the channel, or un-pinned in the channel.
    # @param reason [String, nil] The reason to show in the guild's audit log for pinning or un-pinning the message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Any arguments passed to the builder overwrite method data.
    # @yieldparam view [Webhooks::View] An optional interaction component builder. Any arguments passed to the builder overwrite method data.
    # @return [nil]
    def modify(
      content: :undef, embeds: :undef, flags: :undef, allowed_mentions: :undef,
      components: :undef, attachments: :undef, pinned: :undef, crosspost: :undef,
      has_components: :undef, add_flags: :undef, remove_flags: :undef, reason: nil
    )
      view = Discordrb::Webhooks::View.new
      builder = Discordrb::Webhooks::Builder.new

      builder.content = content
      [*embeds].each { |item| builder << item } unless embeds == :undef
      builder.allowed_mentions = allowed_mentions unless allowed_mentions == :undef
      yield(builder, view) if block_given?

      view = view.to_a
      view = nil unless view.any?
      builder = builder.to_json_hash

      data = {
        content: builder[:content],
        allowed_mentions: builder[:allowed_mentions],
        components: view || (components == :undef ? components : components&.to_a),
        embeds: block_given? && builder[:embeds]&.any? ? builder[:embeds] : embeds
      }

      if attachments != :undef
        attachments = [attachments] unless attachments.is_a?(Array) || attachments.is_a?(Set)

        data[:files] = attachments&.map&.with_index do |attachment, index|
          if attachment.is_a?(Hash)
            attachment
          elsif attachment.respond_to?(:read)
            { file: attachment }
          elsif attachment.respond_to?(:resolve_id)
            { id: attachment.resolve_id }
          else
            raise ArgumentError, "Invalid attachment type: ('#{attachment.class}', #{index})"
          end
        end
      end

      if flags != :undef || has_components == true || add_flags != :undef || remove_flags != :undef
        if flags != :undef && (add_flags != :undef || remove_flags != :undef)
          raise ArgumentError, "'flags' are mutually exclusive with 'add_flags' and 'remove_flags'"
        end

        flags = flags == :undef ? @flags : [*flags].reduce(0) { |sum, bit| sum | (FLAGS[bit] || bit.to_i) }

        if add_flags != :undef || remove_flags != :undef
          to_flags = lambda do |bits|
            bits == :undef ? 0 : [*bits].reduce(0) { |sum, bit| sum | (FLAGS[bit] || bit.to_i) }
          end

          flags = ((flags & ~to_flags.call(remove_flags)) | to_flags.call(add_flags))
        end

        flags |= FLAGS[:uikit_components] if has_components == true

        if flags.anybits?(FLAGS[:uikit_components]) && !uikit_components?
          data.merge!({ content: nil, poll: nil, embeds: [], sticker_ids: [], shared_client_theme: nil })
        end

        data[:flags] = flags
      end

      if pinned == true
        @bot.http.pin_message(@channel_id, @id, reason: reason)
      elsif pinned == false
        @bot.http.unpin_message(@channel_id, @id, reason: reason)
      end

      if crosspost == true && !crossposted?
        update_data(@bot.http.crosspost_message(@channel_id, @id))
      end

      return unless data.any? { |_, value| value != :undef }

      update_data(@bot.http.edit_message(@channel_id, @id, **data))
      nil
    end

    alias_method :edit, :modify
    alias_method :jump_url, :jump_link

    # @!endgroup

    #     ###    ##     ## ######## ##     ##  #######  ########
    #    ## ##   ##     ##    ##    ##     ## ##     ## ##     ##
    #   ##   ##  ##     ##    ##    ##     ## ##     ## ##     ##
    #  ##     ## ##     ##    ##    ######### ##     ## ########
    #  ######### ##     ##    ##    ##     ## ##     ## ##   ##
    #  ##     ## ##     ##    ##    ##     ## ##     ## ##    ##
    #  ##     ##  #######     ##    ##     ##  #######  ##     ##

    # @!group Author

    # Check if the message was sent by a webhook user.
    # @return [true, false] Whether or not the message was sent by a webhook.
    def webhook?
      !@webhook_id.nil?
    end

    # Check if the message was sent by the current bot.
    # @return [true, false] Whether or not the message was sent by the current bot.
    def current_bot?
      return author.current_bot? if @author

      @author_id == @bot.profile.resolve_id
    end

    # Get the user or guild member that sent the message.
    # @return [Member, User] The user that sent the message. Will be a {Member guild member} most of the time for
    #   messages that were sent in a guild, unless the author has left the guild. Will be a {User user} for DM messages.
    def author
      return @author if @author

      unless channel.private?
        @author = channel.guild&.member(@author_id)
        Discordrb::LOGGER.debug("Member (ID: #{@author_id}) not found (possibly left the guild).") unless @author
      end

      @author ||= @bot.user(@author_id)
    end

    alias_method :user, :author
    alias_method :member, :author

    # @!endgroup

    #  ########  ######## ######## ######## ########  ######## ##    ##  ######  ########
    #  ##     ## ##       ##       ##       ##     ## ##       ###   ## ##    ## ##
    #  ##     ## ##       ##       ##       ##     ## ##       ####  ## ##       ##
    #  ########  ######   ######## ######## ########  ######   ## ## ## ##       ######
    #  ##   ##   ##       ##       ##       ##   ##   ##       ##  #### ##       ##
    #  ##    ##  ##       ##       ##       ##    ##  ##       ##   ### ##    ## ##
    #  ##     ## ######## ##       ######## ##     ## ######## ##    ##  ######  ########

    # @!group Replies and Forwards

    # Send a message replying to this message.
    # @param must_exist [true, false] whether to raise an exception if the
    #   message has been deleted instead of sending a normal (non-reply) message.
    # @return [Message] The message that was created.
    def reply(must_exist: true, **)
      channel.send_message(**, reference: to_reference(type: :reply, must_exist:))
    end

    # Forward the message to another channel.
    # @param channel [Channel, Integer, String] The channel to forward the message to.
    # @return [Message] The message that was created.
    def forward(channel:, **)
      @bot.channel(channel).send_message(**, reference: to_reference(type: :forward))
    end

    # Convert the message into a hash that can be used to reference the message in a forward or a reply.
    # @param type [Integer, Symbol] The reference type to set. Can either be one of `:reply` or `:forward`.
    # @param must_exist [true, false] Whether to raise an error if this message was deleted when sending it.
    # @return [Hash] The message as a hash representation that can be used in a forwarded message or a reply.
    def to_reference(type: :reply, must_exist: true)
      type = type.is_a?(Numeric) ? type : Message::Reference::TYPES[type.to_sym]

      { type: type, message_id: @id, channel_id: @channel_id, fail_if_not_exists: must_exist }
    end

    # @!endgroup

    #  ########  ########    ###     ######  ######## ####  ####### ##    ##  ######
    #  ##     ## ##         ## ##   ##    ##   ##     ##  ##     ## ###   ## ##    ##
    #  ##     ## ##        ##   ##  ##         ##     ##  ##     ## ####  ## ##
    #  ########  ######   ##     ## ##         ##     ##  ##     ## ## ## ##  ######
    #  ##   ##   ##       ######### ##         ##     ##  ##     ## ##  ####       ##
    #  ##    ##  ##       ##     ## ##    ##   ##     ##  ##     ## ##   ### ##    ##
    #  ##     ## ######## ##     ##  ######    ##    ####  #######  ##    ##  ######

    # @!group Reactions

    # Add a reaction to the message.
    # @param emoji [Emoji, Reaction, String] The emoji to react with.
    # @return [nil]
    def add_reaction(emoji:)
      emoji = emoji.to_reaction unless emoji.is_a?(String)
      @bot.http.create_reaction(@channel_id, @id, emoji)
      nil
    end

    # Remove one or more reactions from the message.
    # @example Remove all of the reactions on the message.
    #   message.remove_reactions
    # @example Remove all of the reactions for a specific emoji.
    #   message.remove_reaction(emoji: '🍞')
    # @example A shortcut to remove a reaction for the current bot.
    #   message.remove_reaction(emoji: '🍞', user: :current_bot)
    # @example Remove a specific user's reaction for a specific emoji.
    #   message.remove_reaction(emoji: '🍞', user: 171764626755813376)
    # @param emoji [Emoji, Reaction, String, nil] The emoji to remove reactions for.
    # @param user [User, Member, Integer, String, nil] The user whose reaction should removed.
    # @return [nil]
    def remove_reaction(emoji: nil, user: nil)
      me = @bot.profile.id
      user = (user == :current_bot ? me : user&.resolve_id)
      emoji = emoji&.to_reaction unless emoji.is_a?(String)

      if emoji.nil?
        @bot.http.delete_all_reactions(@channel_id, @id)
      elsif user.nil?
        @bot.http.delete_all_reactions_for_emoji(@channel_id, @id, emoji)
      elsif user != me
        @bot.http.delete_user_reaction(@channel_id, @id, emoji, user)
      else
        @bot.http.delete_own_reaction(@channel_id, @id, emoji)
      end

      nil
    end

    # Get the users who reacted with a specific emoji.
    # @param emoji [Emoji, Reaction, String] The emoji to retrieve reactions for.
    # @param type [Integer, Symbol, nil] The type of the reactions to fetch (`:normal`, or `:burst`).
    # @param limit [Integer, nil] The maximum number of users to fetch, or `nil` to fetch all of them.
    # @return [Array<User>] The users who reacted using the emoji, ordered in ascending order by user ID.
    def reacted_with(emoji:, type: :normal, limit: 100)
      type = Reaction::TYPES[type] || type
      emoji = emoji.to_reaction unless emoji.is_a?(String)

      get_reactions = lambda do |limit_, after = nil|
        response = @bot.http.list_reactions(@channel_id, @id, emoji, limit: limit_, after:, type:)
        response.collect { |reaction_user_data| @bot.ensure_user(reaction_user_data, true) }
      end

      # Can be done without pagination
      return get_reactions.call(limit) if limit && limit <= 100

      paginator = Paginator.new(limit, :down) do |last_page|
        if last_page && last_page.count < 100
          []
        else
          get_reactions.call(100, last_page&.last&.id)
        end
      end

      paginator.to_a
    end

    alias_method :remove_reactions, :remove_reaction

    # @!endgroup

    #     ###    ##        ##    ###    #### ########  ######
    #    ## ##   ##        ##   ## ##    ##     ##    ##    ##
    #   ##   ##  ##        ##  ##   ##   ##     ##    ##
    #  ##     ## ##   ##   ## ##     ##  ##     ##     ######
    #  ######### ##  ####  ## #########  ##     ##          ##
    #  ##     ## #### ## #### ##     ##  ##     ##    ##    ##
    #  ##     ##  ##      ##  ##     ## ####    ##     ######

    # @!group Awaits

    # Add a blocking {Await} for a reaction to be added on the message.
    # @see Bot#add_await!
    def await_reaction!(attributes = {}, &block)
      @bot.add_await!(Discordrb::Events::ReactionAddEvent, { message: @id }.merge!(attributes), &block)
    end

    # Add n non-blocking {Await} for a reaction to be added on the message.
    # @see Bot#add_await
    def await_reaction(key, attributes = {}, &block)
      @bot.add_await(key, Discordrb::Events::ReactionAddEvent, { message: @id }.merge!(attributes), &block)
    end

    # Add a blocking {Await} for a message sent by the same user in the same channel.
    # @see Bot#add_await!
    def await!(attributes = {}, &block)
      @bot.add_await!(Discordrb::Events::MessageEvent, { from: author.id, in: @channel_id }.merge!(attributes), &block)
    end

    # Add an non-blocking {Await} for a message sent by the same user in the same channel.
    # @see Bot#add_await
    def await(key, attributes = {}, &block)
      @bot.add_await(key, Discordrb::Events::MessageEvent, { from: author.id, in: @channel_id }.merge!(attributes), &block)
    end

    # @!endgroup

    #  ######## ##    ## ######## ########  ######
    #     ##     ##  ##  ##     ## ##      ##    ##
    #     ##      ####   ##     ## ##      ##
    #     ##       ##    ########  ######   ######
    #     ##       ##    ##        ##            ##
    #     ##       ##    ##        ##       ##   ##
    #     ##       ##    ##        ########  ######

    # @!group Types

    # @!method default?
    #   @return [true, false] whether the message is a normal message.
    # @!method thread_member_add?
    #   @return [true, false] whether the message was sent because a user was added to a thread.
    # @!method thread_member_remove?
    #   @return [true, false] whether the message was sent because a user was removed from a thread.
    # @!method call?
    #   @return [true, false] whether the message was sent because a user started a call in a private channel.
    # @!method channel_name_change?
    #   @return [true, false] whether the message was sent because the thread's name was changed.
    # @!method channel_pinned_message?
    #   @return [true, false] whether the message was sent because a message was pinned in the channel.
    # @!method guild_member_join?
    #   @return [true, false] whether the message was sent because a new member joined the guild.
    # @!method premium_guild_subscription?
    #   @return [true, false] whether the message was sent because a user boosted the guild.
    # @!method guild_premium_tier_one?
    #   @return [true, false] whether the message was sent because because the guild reached premium tier (boost level) one.
    # @!method guild_premium_tier_two?
    #   @return [true, false] whether the message was sent because because the guild reached premium tier (boost level) two.
    # @!method guild_premium_tier_three?
    #   @return [true, false] whether the message was sent because because the guild reached premium tier (boost level) three.
    # @!method channel_follow_add?
    #   @return [true, false] whether the message was sent because an announcement channel was {Channel#follow followed}.
    # @!method guild_discovery_disqualified?
    #   @return [true, false] whether the message was sent because the guild was disqualified from discovery.
    # @!method guild_discovery_requalified?
    #   @return [true, false] whether the message was sent because the guild was requalified for discovery.
    # @!method guild_discovery_grace_period_initial_warning?
    #   @return [true, false] whether the message was sent because the guild has failed discovery requirements for 1 week.
    # @!method guild_discovery_grace_period_final_warning?
    #   @return [true, false] whether the message was sent because the guild has failed discovery requirements for 3 weeks.
    # @!method thread_created?
    #   @return [true, false] whether the message was sent because a thread was created.
    # @!method reply?
    #   @return [true, false] whether the message is a reply to another message.
    # @!method chat_input_command?
    #   @return [true, false] whether the message is a chat-input application command.
    # @!method thread_starter_message?
    #   @return [true, false] whether the message was sent because a thread starter message was added to a thread.
    # @!method guild_invite_reminder?
    #   @return [true, false] whether the message was sent to remind users to invite friends to the guild.
    # @!method context_menu_command?
    #   @return [true, false] whether the message was sent because a user executed a context menu command.
    # @!method automod_action?
    #   @return [true, false] whether the message was sent because AutoMod took an action.
    # @!method role_subscription_purchase?
    #   @return [true, false] whether the message was sent because a user purchased or renewed a role subscription.
    # @!method interaction_premium_upsell?
    #   @return [true, false] whether the message was sent in order to advertise a premium interaction.
    # @!method stage_start?
    #   @return [true, false] whether the message was sent because a stage instance started.
    # @!method stage_end?
    #   @return [true, false] whether the message was sent because a stage instance eneded.
    # @!method stage_speaker?
    #   @return [true, false] whether the message was sent because a user started speaking in a stage channel.
    # @!method stage_raise_hand?
    #   @return [true, false] whether the message was sent because a user raised their hand in a stage channel.
    # @!method stage_topic?
    #   @return [true, false] whether the message was sent because a stage instance's topic was changed.
    # @!method guild_application_premium_subscription?
    #   @return [true, false] whether the message was sent because a user purchased an application's premium subscription.
    # @!method guild_incident_alert_mode_enabled?
    #   @return [true, false] whether the message was sent because a user enabled lockdown mode for a guild.
    # @!method guild_incident_alert_mode_disabled?
    #   @return [true, false] whether the message was sent because a user disabled lockdown mode for a guild.
    # @!method guild_incident_report_raid?
    #   @return [true, false] whether the message was sent because a user reported a raid for a guild.
    # @!method guild_incident_report_false_alarm?
    #   @return [true, false] whether the message was sent because a user reported a false alarm for a raid.
    # @!method purchase_notification?
    #   @return [true, false] whether the message was sent because a user purchased a guild product.
    # @!method poll_result?
    #   @return [true, false] whether the message was sent because the results for a poll were finalized.
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

    # @!method crossposted?
    #   @return [true, false] whether the message has been published.
    # @!method crosspost?
    #   @return [true, false] whether the message was sent as a result of a message being published.
    # @!method suppress_embeds?
    #   @return [true, false] whether the embeds attached to the message will be hidden.
    # @!method source_message_deleted?
    #   @return [true, false] whether the original crossposted message has been deleted.
    # @!method urgent?
    #   @return [true, false] whether the message was sent by Discord's offical urgent messaging system.
    # @!method thread?
    #   @return [true, false] whether the message has an associated thread with the same ID.
    # @!method ephemeral?
    #   @return [true, false] whether the message is only visible to the user who invoked the interaction.
    # @!method loading?
    #  @return [true, false] whether the message is an interaction response that is "thinking".
    # @!method failed_to_mention_roles?
    #   @return [true, false] whether the message failed to mention some roles in a thread and add their member.
    # @!method suppress_notifications?
    #   @return [true, false] whether any mentions triggered via the message will not send a push-notification.
    # @!method voice_message?
    #   @return [true, false] whether the message is a voice message.
    # @!method snapshot?
    #   @return [true, false] whether the message contains a message snapshot.
    # @!method uikit_components?
    #   @return [true, false] whether the message is using the advanced components system.
    FLAGS.each do |name, value|
      define_method("#{name}?") { @flags.anybits?(value) }
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
    def inspect
      "<Message id=#{@id} type=#{@type} channel_id=#{@channel_id}>"
    end

    # @!visibility private
    def update_data(new_data)
      @flags = new_data[:flags] || 0
      @mentions = new_data[:mentions]&.map { |item| @bot.ensure_user(item) } || []

      @pinned = new_data[:pinned]
      @mentions_everyone = new_data[:mention_everyone]
      @mention_roles = new_data[:mention_roles]&.map(&:to_i)
      @edited_at = Time.iso8601(new_data[:edit_timestamp]) if new_data[:edit_timestamp]

      @embeds = new_data[:embeds]&.map { |item| Embed.new(item, @bot) } || []
      @reactions = new_data[:reactions]&.map { |item| Reaction.new(item, self, @bot) } || []
      @attachments = new_data[:attachments]&.map { |item| Attachment.new(item, self, @bot) } || []

      @components = new_data[:components]&.filter_map { |item| Components.from_data(item, @bot) } || []
      @stickers = (new_data[:sticker_items] || new_data[:stickers])&.map { |item| Sticker::Item.new(item, @bot) } || []

      if (reference = new_data[:message_reference])
        if new_data.key?(:referenced_message)
          reference[:message] = new_data[:referenced_message]
        end

        @reference = MessageReference.new(reference, @bot)
      end

      if new_data[:content] != @content
        # Reset the data that has been parsed from the message content.
        @games = nil
        @emojis = nil
        @timestamps = nil
      end

      if (poll = new_data[:poll])
        @poll ||= Poll.new(poll, self, @bot)
        @poll&.process_answers(poll[:answers], poll[:results]&.[](:answer_counts))
      else
        @poll = nil
      end

      @content = new_data[:content]
      @call = new_data[:call] ? Call.new(new_data[:call], @bot) : nil
      @activity = new_data[:activity] ? MessageActivity.new(new_data[:activity], @bot) : nil
      @client_theme = new_data[:shared_client_theme] ? ClientTheme.new(new_data[:shared_client_theme], @bot) : nil
    end
  end
end
