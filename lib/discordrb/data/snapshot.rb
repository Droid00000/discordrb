# frozen_string_literal: true

module Discordrb
  # A partial and immutable copy of a message that has been forwarded.
  class Snapshot
    # @return [Integer] the message type of the message snapshot.
    attr_reader :type

    # @return [String] the text content of the message snapshot.
    attr_reader :content

    # @return [Array<Embed>] the embeds attached to the message snapshot.
    attr_reader :embeds

    # @return [Array<Attachment>] the files attached to the message snapshot.
    attr_reader :attachments

    # @return [Time, nil] the time at which the message snapshot was edited.
    attr_reader :edited_at

    # @return [Time] the time at when the snapshot's source message was created.
    attr_reader :creation_time

    # @return [Integer] the flags that have been set on the message snapshot.
    attr_reader :flags

    # @return [Array<User>] the users that were mentioned in the message snapshot.
    attr_reader :mentions

    # @return [Array<Component>] the interaction components associated with the message snapshot.
    attr_reader :components

    # @return [Array<Sticker::Item>] the stickers included in the message snapshot.
    attr_reader :stickers

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @type = data[:type]
      @flags = data[:flags] || 0
      @content = data[:content]
      @mention_roles = data[:mention_roles]&.map(&:resolve_id) || []
      @embeds = data[:embeds]&.map { |embed| Embed.new(embed, @bot) } || []
      @attachments = data[:attachments]&.map { |file| Attachment.new(file, self, @bot) } || []
      @creation_time = data[:timestamp] ? Time.iso8601(data[:timestamp]) : nil
      @edited_at = data[:edited_timestamp] ? Time.iso8601(data[:edited_timestamp]) : nil
      @mentions = data[:mentions]&.map { |mention| @bot.ensure_user(mention) } || []
      @components = data[:components]&.map { |component| Components.from_data(component, @bot) } || []
      @stickers = (data[:sticker_items] || data[:stickers])&.map { |item| Sticker::Item.new(item, @bot) } || []
    end

    # Check whether the message snapshot has been edited.
    # @return [true, false] whether the snapshot was edited or not.
    def edited?
      !@edited_at.nil?
    end

    # Get the custom emojis that were used in the message snapshot.
    # @return [Array<Emoji>] The custom emojis that were used in the message snapshot.
    def emojis
      return (@emojis || []) if @emojis || !@content || @content.empty?

      @emojis = []

      @content.scan(/<(a?):(\w{2,32}):(\d{15,32})>/) do |type, name, id|
        id = id.to_i
        animated = (type == 'a')
        @emojis << (@bot.emoji(id) || Emoji.new({ id:, name:, animated: }, @bot))
      end

      @emojis
    end

    # Get the formatted timestamps contained in the message snapshot..
    # @return [Array<TimestampMarkdown>] The formatted timestamps in the message snapshot.
    def timestamps
      return (@fmt_timestamps || []) if @fmt_timestamps || !@content || @content.empty?

      @fmt_timestamps = []

      @content.scan(/<t:(-?\d{1,13})(?::(t|T|d|D|f|F|s|S|R))?>/) do |time, specifier|
        # If it's not between these values, Discord won't show it, so don't even bother.
        if (time = time.to_i).between?(-8_640_000_000_000, 8_640_000_000_000)
          @fmt_timestamps << TimestampMarkdown.new(Time.at(time), specifier)
        end
      end

      @fmt_timestamps
    end

    # Get the roles that were mentioned in the message snapshot.
    # @return [Array<Role>] the roles that were mentioned in the message snapshot.
    # @note this can only resolve roles in guilds that the bot has access to via {Bot#guilds}.
    def role_mentions
      return [] if @mention_roles.empty?

      return @role_mentions if @role_mentions

      source_guild = nil

      @role_mentions = @mention_roles.filter_map do |role_id|
        if source_guild
          source_guild.role(role_id)
        else
          @bot.guilds.each do |guild|
            if (role = guild.role(role_id))
              source_guild = guild
              break role
            else
              next
            end
          end
        end
      end
    end

    # Get the buttons that were used in the message snapshot.
    # @return [Array<Components::Button>] the button components used in the message snapshot.
    def buttons
      buttons = @components.flat_map do |component|
        case component
        when Components::Button
          component
        when Components::Section
          component.accessory if component.accessory.is_a?(Components::Button)
        when Components::ActionRow, Components::Container
          component.buttons
        end
      end

      buttons.compact
    end

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
    Message::TYPES.each do |name, value|
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
    Message::FLAGS.each do |name, value|
      define_method("#{name}?") { @flags.anybits?(value) }
    end

    # @!endgroup
  end
end
