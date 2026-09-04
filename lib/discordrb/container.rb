# frozen_string_literal: true

require 'discordrb/events/message'
require 'discordrb/events/typing'
require 'discordrb/events/lifetime'
require 'discordrb/events/presence'
require 'discordrb/events/voice_state_update'
require 'discordrb/events/voice_server_update'
require 'discordrb/events/channels'
require 'discordrb/events/members'
require 'discordrb/events/roles'
require 'discordrb/events/guilds'
require 'discordrb/events/await'
require 'discordrb/events/bans'
require 'discordrb/events/reactions'
require 'discordrb/events/interactions'
require 'discordrb/events/integrations'
require 'discordrb/events/scheduled_events'
require 'discordrb/events/polls'
require 'discordrb/events/auto_moderation'
require 'discordrb/events/soundboard_sounds'
require 'discordrb/events/stage_instances'
require 'discordrb/events/join_requests'
require 'discordrb/await'

module Discordrb
  # This module provides the functionality required for events and awaits. It is separated
  #   from the {Bot} class so users can make their own container modules and include them.
  module EventContainer
    # This **event** is raised whenever a message is created in a channel.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :start_with Matches the string the message starts with.
    # @option attributes [String, Regexp] :end_with Matches the string the message ends with.
    # @option attributes [String, Regexp] :contains Matches a string the message contains.
    # @option attributes [String, Integer, Channel] :in Matches the channel the message was sent in.
    # @option attributes [String, Integer, User] :from Matches the user that sent the message.
    # @option attributes [String] :content Exactly matches the entire content of the message.
    # @option attributes [Time] :after Matches a time after the time the message was sent at.
    # @option attributes [Time] :before Matches a time before the time the message was sent at.
    # @option attributes [Boolean] :private Matches whether or not the channel is private.
    # @option attributes [Integer, String, Symbol] :type Matches the type of the message that was sent.
    # @option attributes [Guild, Integer, String] :guild Matches the guild the message was sent in.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MessageEvent] The event that was raised.
    # @return [MessageEventHandler] the event handler that was registered.
    def message(attributes = {}, &block)
      register_event(MessageEvent, attributes, block)
    end

    # This **event** is raised whenever the bot is initialized READY (guilds and channels) have
    #   finished loading. It's the recommended way to do things when the bot has finished starting up.
    # @param attributes [Hash] Event attributes, none in this particular case
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ReadyEvent] The event that was raised.
    # @return [ReadyEventHandler] the event handler that was registered.
    def ready(attributes = {}, &block)
      register_event(ReadyEvent, attributes, block)
    end

    # This **event** is raised whenever the bot successfully resumes a Gateway session.
    # @param attributes [Hash] Event attributes, none in this particular case.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ResumedEvent] The event that was raised.
    # @return [ResumedEventHandler] the event handler that was registered.
    def resumed(attributes = {}, &block)
      register_event(ResumedEvent, attributes, block)
    end

    # This **event** is raised whenever the bot has disconnected from the WebSocket, due to the {Bot#stop} method or
    #   external causes. It's the recommended way to do clean-up tasks.
    # @param attributes [Hash] Event attributes, none in this particular case
    # @yield The block is executed when the event is raised.
    # @yieldparam event [DisconnectEvent] The event that was raised.
    # @return [DisconnectEventHandler] the event handler that was registered.
    def disconnected(attributes = {}, &block)
      register_event(DisconnectEvent, attributes, block)
    end

    # This **event** is raised whenever a user starts typing in a channel.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @option attributes [Integer, String, User, Member] :user Matches the user that started typing.
    # @option attributes [Time] :after Matches a time after the time the user started typing.
    # @option attributes [Time] :before Matches a time before the time the user started typing.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [TypingStartEvent] The event that was raised.
    # @return [TypingStartEventHandler] the event handler that was registered.
    def typing(attributes = {}, &block)
      register_event(TypingStartEvent, attributes, block)
    end

    # This **event** is raised whenever a message is deleted in a channel.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer] :id Matches the ID of the message that was deleted.
    # @option attributes [String, Integer, Channel] :in Matches the channel the message was deleted in.
    # @option attributes [Guild, Integer, String] :guild Matches the guild the message was deleted in.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MessageDeleteEvent] The event that was raised.
    # @return [MessageDeleteEventHandler] the event handler that was registered.
    def message_delete(attributes = {}, &block)
      register_event(MessageDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever a message is edited in a channel.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer] :id Matches the ID of the message that was updated.
    # @option attributes [String, Integer, Channel] :in Matches the channel the message was updated in.
    # @option attributes [Integer, String, Symbol] :type Matches the type of the message that was updated.
    # @option attributes [Guild, Integer, String] :guild Matches the guild the message was updated in.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MessageUpdateEvent] The event that was raised.
    # @return [MessageUpdateEventHandler] the event handler that was registered.
    def message_update(attributes = {}, &block)
      register_event(MessageUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever somebody reacts to a message.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @option attributes [Integer, String, Message] :message A message to match against.
    # @option attributes [Integer, String, Emoji, Reaction] :emoji An emoji to match against.
    # @option attributes [Integer, String, Symbol] :type A reaction type to match against.
    # @option attributes [User, Member, Integer, String] :message_author A message author to match against.
    # @option attributes [User, Member, Integer, String] :user A user to match against. Can also be passed as `:member`.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MessageReactionAddEvent] The event that was raised.
    # @return [MessageReactionAddEventHandler] The event handler that was registered.
    def reaction_add(attributes = {}, &block)
      register_event(MessageReactionAddEvent, attributes, block)
    end

    # This **event** is raised whenever somebody removes a reaction from a message.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @option attributes [Integer, String, Message] :message A message to match against.
    # @option attributes [Integer, String, Emoji, Reaction] :emoji An emoji to match against.
    # @option attributes [Integer, String, Symbol] :type A reaction type to match against.
    # @option attributes [User, Member, Integer, String] :user A user to match against. Can also be passed as `:member`.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MessageReactionRemoveEvent] The event that was raised.
    # @return [MessageReactionRemoveEventHandler] The event handler that was registered.
    def reaction_remove(attributes = {}, &block)
      register_event(MessageReactionRemoveEvent, attributes, block)
    end

    # This **event** is raised whenever somebody removes every reaction from a message.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @option attributes [Integer, String, Message] :message A message to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MessageReactionRemoveAllEvent] The event that was raised.
    # @return [MessageReactionRemoveAllEventHandler] The event handler that was registered.
    def reaction_remove_all(attributes = {}, &block)
      register_event(MessageReactionRemoveAllEvent, attributes, block)
    end

    # This **event** is raised whenever somebody removes all instances of
    #   a single reaction from a message.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @option attributes [Integer, String, Message] :message A message to match against.
    # @option attributes [Integer, String, Emoji, Reaction] :emoji An emoji to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MessageReactionRemoveEmojiEvent] The event that was raised.
    # @return [MessageReactionRemoveEmojiEventHandler] The event handler that was registered.
    def reaction_remove_emoji(attributes = {}, &block)
      register_event(MessageReactionRemoveEmojiEvent, attributes, block)
    end

    # This **event** is raised whenever a user's status (online/offline/idle) changes.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, User] :from Matches the user whose status changed.
    # @option attributes [:offline, :idle, :online] :status Matches the status the user has now.
    # @option attributes [Hash<Symbol, Symbol>] :client_status Matches the current online status (`:online`, `:idle` or `:dnd`) of the user
    #   on various device types (`:desktop`, `:mobile`, or `:web`). The value will be `nil` when the user is offline or invisible
    # @yield The block is executed when the event is raised.
    # @yieldparam event [PresenceEvent] The event that was raised.
    # @return [PresenceEventHandler] the event handler that was registered.
    def presence(attributes = {}, &block)
      register_event(PresenceEvent, attributes, block)
    end

    # This **event** is raised whenever the bot is mentioned in a message.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :start_with Matches the string the message starts with.
    # @option attributes [String, Regexp] :end_with Matches the string the message ends with.
    # @option attributes [String, Regexp] :contains Matches a string the message contains.
    # @option attributes [String, Integer, Channel] :in Matches the channel the message was sent in.
    # @option attributes [String, Integer, User] :from Matches the user that sent the message.
    # @option attributes [String] :content Exactly matches the entire content of the message.
    # @option attributes [Time] :after Matches a time after the time the message was sent at.
    # @option attributes [Time] :before Matches a time before the time the message was sent at.
    # @option attributes [Boolean] :private Matches whether or not the channel is private.
    # @option attributes [Integer, String, Symbol] :type Matches the type of the message that was sent.
    # @option attributes [true, false] :role_mention If the event should trigger when the bot's managed role is mentioned.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MentionEvent] The event that was raised.
    # @return [MentionEventHandler] the event handler that was registered.
    def mention(attributes = {}, &block)
      register_event(MentionEvent, attributes, block)
    end

    # This **event** is raised whenever a channel is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Channel] :id A channel ID to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A channel name to match against.
    # @option attributes [String, Regexp] :topic A channel topic to match against.
    # @option attributes [Integer, Symbol] :type A channel type to match against.
    # @option attributes [true, false] :locked Match whether or not the thread is locked.
    # @option attributes [true, false] :archived Match whether or not the thread is locked.
    # @option attributes [Integer, String, Channel] :parent A parent channel to match against.
    # @option attributes [Integer] :auto_archive_duration A thread auto archive duration to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ChannelCreateEvent] The event that was raised.
    # @return [ChannelCreateEventHandler] the event handler that was registered.
    def channel_create(attributes = {}, &block)
      register_event(ChannelCreateEvent, attributes, block)
    end

    # This **event** is raised whenever a channel is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Channel] :id A channel ID to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A channel name to match against.
    # @option attributes [String, Regexp] :topic A channel topic to match against.
    # @option attributes [Integer, Symbol] :type A channel type to match against.
    # @option attributes [true, false] :locked Match whether or not the thread is locked.
    # @option attributes [true, false] :archived Match whether or not the thread is locked.
    # @option attributes [Integer, String, Channel] :parent A parent channel to match against.
    # @option attributes [Integer] :auto_archive_duration A thread auto archive duration to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ChannelUpdateEvent] The event that was raised.
    # @return [ChannelUpdateEventHandler] the event handler that was registered.
    def channel_update(attributes = {}, &block)
      register_event(ChannelUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a channel is deleted.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Channel] :id A channel ID to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A channel name to match against.
    # @option attributes [String, Regexp] :topic A channel topic to match against.
    # @option attributes [Integer, Symbol] :type A channel type to match against.
    # @option attributes [Integer, String, Channel] :parent A parent channel to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ChannelDeleteEvent] The event that was raised.
    # @return [ChannelDeleteEventHandler] the event handler that was registered.
    def channel_delete(attributes = {}, &block)
      register_event(ChannelDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever the status for a voice channel is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :status Matches the new status of the voice channel.
    # @option attributes [String, Integer, Guild] :guild Matches the guild where the status was updated.
    # @option attributes [String, Integer, Channel] :channel Matches the channel where the status was updated.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [VoiceChannelStatusUpdateEvent] The event that was raised.
    # @return [VoiceChannelStatusUpdateEventHandler] the event handler that was registered.
    def channel_status_update(attributes = {}, &block)
      register_event(VoiceChannelStatusUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever the start time for a voice channel is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Time] :after Matches a time after the start time of the voice channel.
    # @option attributes [Time] :before Matches a time before the start time of the voice channel.
    # @option attributes [String, Integer, Guild] :guild Matches the guild where the start time was updated.
    # @option attributes [String, Integer, Channel] :channel Matches the channel where the start time was updated.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [VoiceChannelStartTimeUpdateEvent] The event that was raised.
    # @return [VoiceChannelStartTimeUpdateEventHandler] the event handler that was registered.
    def channel_start_time_update(attributes = {}, &block)
      register_event(VoiceChannelStartTimeUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a member's voice state is updated, e.g. when the member is muted or deafened.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @option attributes [Integer, String, Channel] :old_channel The previous channel the member was connected to, to match against.
    # @option attributes [true, false] :muted Matches whether or not the member is muted.
    # @option attributes [true, false] :camera Matches whether or not the the member has enabled their webcam.
    # @option attributes [true, false] :deafened Matches whether or not the member is deafened by the guild.
    # @option attributes [true, false] :streaming Matches whether or not the member is streaming using "Go Live".
    # @option attributes [true, false] :suppressed Matches whether or not the member is suppressed in the stage channel.
    # @option attributes [true, false] :self_muted Matches whether or not the member has locally muted themselves.
    # @option attributes [true, false] :self_deafened Matches whether or not the member has locally deafened themselves.
    # @option attributes [true, false] :requested_to_speak Matches whether ot not the member requested to speak in the stage channel.
    # @option attributes [Integer, String, User, Member] :member A member to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [VoiceStateUpdateEvent] The event that was raised.
    # @return [VoiceStateUpdateEventHandler] the event handler that was registered.
    def voice_state_update(attributes = {}, &block)
      register_event(VoiceStateUpdateEvent, attributes, block)
    end

    # This **event** is raised when first connecting to a guild's voice channel.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [VoiceServerUpdateEvent] The event that was raised.
    # @return [VoiceServerUpdateEventHandler] The event handler that was registered.
    def voice_server_update(attributes = {}, &block)
      register_event(VoiceServerUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a user joins a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, User] :user A user to match against.
    # @option attributes [Guild, Integer, String] :guild A guild to match against.
    # @option attributes [true, false] :pending Matches whether the guild member is pending.
    # @option attributes [String, Regexp] :nickname A nickname to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildMemberAddEvent] The event that was raised.
    # @return [GuildMemberAddEventHandler] the event handler that was registered.
    def member_add(attributes = {}, &block)
      register_event(GuildMemberAddEvent, attributes, block)
    end

    # This **event** is raised whenever a guild member is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, User] :user A user to match against.
    # @option attributes [Guild, Integer, String] :guild A guild to match against.
    # @option attributes [true, false] :pending Matches whether the guild member is pending.
    # @option attributes [String, Regexp] :nickname A nickname to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildMemberUpdateEvent] The event that was raised.
    # @return [GuildMemberUpdateEventHandler] the event handler that was registered.
    def member_update(attributes = {}, &block)
      register_event(GuildMemberUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a guild member is removed.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, User] :user A user to match against.
    # @option attributes [Guild, Integer, String] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildMemberDeleteEvent] The event that was raised.
    # @return [GuildMemberDeleteEventHandler] the event handler that was registered.
    def member_leave(attributes = {}, &block)
      register_event(GuildMemberRemoveEvent, attributes, block)
    end

    # This **event** is raised whenever a user is banned from a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, User] :user A user to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildBanAddEvent] The event that was raised.
    # @return [GuildBanAddEventHandler] the event handler that was registered.
    def ban_create(attributes = {}, &block)
      register_event(GuildBanAddEvent, attributes, block)
    end

    # This **event** is raised whenever a user is unbanned from a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, User] :user A user to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildBanRemoveEvent] The event that was raised.
    # @return [GuildBanRemoveEventHandler] the event handler that was registered.
    def ban_delete(attributes = {}, &block)
      register_event(GuildBanRemoveEvent, attributes, block)
    end

    # This **event** is raised whenever an audit log entry is created in a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild Matches the guild the entry was created in.
    # @option attributes [String, Symbol, Integer] :action Matches the type of the entry.
    # @option attributes [String, Regexp] :reason Matches the reason associated with the entry.
    # @option attributes [String, Integer, User, Member] :user Matches the user or bot that made the changes.
    # @option attributes [String, Integer, #resolve_id] :target Matches the ID of the affected entity.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildAuditLogEntryCreateEvent] The event that was raised.
    # @return [GuildAuditLogEntryCreateEventHandler] the event handler that was registered.
    def audit_log_entry(attributes = {}, &block)
      register_event(GuildAuditLogEntryCreateEvent, attributes, block)
    end

    # This **event** is raised whenever the bot is added to a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :id A guild ID to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [Integer, String, User, Member] :owner An owner to match against.
    # @option attributes [String, Regexp, Symbol] :locale A locale to match against.
    # @option attributes [Integer, String, Symbol] :nsfw_level An NSFW level to match against.
    # @option attributes [String, Regexp] :description A description to match against.
    # @option attributes [String, Regexp] :vanity_invite_code A vanity invite code to match against.
    # @option attributes [Integer] :premium_tier A boost level to match against.
    # @option attributes [Integer] :premium_count The number of boosts to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildCreateEvent] The event that was raised.
    # @return [GuildCreateEventHandler] the event handler that was registered.
    def guild_create(attributes = {}, &block)
      register_event(GuildCreateEvent, attributes, block)
    end

    # This **event** is raised whenever a guild is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :id A guild ID to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [Integer, String, User, Member] :owner An owner to match against.
    # @option attributes [String, Regexp, Symbol] :locale A locale to match against.
    # @option attributes [Integer, String, Symbol] :nsfw_level An NSFW level to match against.
    # @option attributes [String, Regexp] :description A description to match against.
    # @option attributes [String, Regexp] :vanity_invite_code A vanity invite code to match against.
    # @option attributes [Integer] :premium_tier A boost level to match against.
    # @option attributes [Integer] :premium_count The number of boosts to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildUpdateEvent] The event that was raised.
    # @return [GuildUpdateEventHandler] the event handler that was registered.
    def guild_update(attributes = {}, &block)
      register_event(GuildUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a guild is deleted, or when the bot
    #   is removed from a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :id A guild ID to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildDeleteEvent] The event that was raised.
    # @return [GuildDeleteEventHandler] the event handler that was registered.
    def guild_delete(attributes = {}, &block)
      register_event(GuildDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever the emojis for a guild are updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildEmojisUpdateEvent] The event that was raised.
    # @return [GuildEmojisUpdateEventHandler] the event handler that was registered.
    def guild_emojis_update(attributes = {}, &block)
      register_event(GuildEmojisUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a guild role is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Role] :id A role ID to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [true, false] :hoisted Matches whether the role is hoisted.
    # @option attributes [String, Regexp] :unicode_emoji A unicode emoji to match against.
    # @option attributes [true, false] :mentionable Matches whether the role is mentionable.
    # @option attributes [ColorRGB, Integer] :colour A role colour to match against.
    # @option attributes [Integer, String, User, Member] :bot_id A bot ID to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildRoleCreateEvent] The event that was raised.
    # @return [GuildRoleCreateEventHandler] the event handler that was registered.
    def role_create(attributes = {}, &block)
      register_event(GuildRoleCreateEvent, attributes, block)
    end

    # This **event** is raised whenever a guild role is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Role] :id A role ID to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [true, false] :hoisted Matches whether the role is hoisted.
    # @option attributes [String, Regexp] :unicode_emoji A unicode emoji to match against.
    # @option attributes [true, false] :mentionable Matches whether the role is mentionable.
    # @option attributes [ColorRGB, Integer] :colour A role colour to match against.
    # @option attributes [Integer, String, User, Member] :bot_id A bot ID to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildRoleUpdateEvent] The event that was raised.
    # @return [GuildRoleUpdateEventHandler] the event handler that was registered.
    def role_update(attributes = {}, &block)
      register_event(GuildRoleUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a guild role is deleted.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Role] :id A role ID to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildRoleDeleteEvent] The event that was raised.
    # @return [GuildRoleDeleteEventHandler] the event handler that was registered.
    def role_delete(attributes = {}, &block)
      register_event(GuildRoleDeleteEvent, attributes, block)
    end

    # This **event** is raised when an {Await} is triggered. It provides an easy way to execute code
    # on an await without having to rely on the await's block.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Symbol] :key Exactly matches the await's key.
    # @option attributes [Class] :type Exactly matches the event's type.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [AwaitEvent] The event that was raised.
    # @return [AwaitEventHandler] the event handler that was registered.
    def await(attributes = {}, &block)
      register_event(AwaitEvent, attributes, block)
    end

    # This **event** is raised whenever a private message is sent to the bot.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :start_with Matches the string the message starts with.
    # @option attributes [String, Regexp] :end_with Matches the string the message ends with.
    # @option attributes [String, Regexp] :contains Matches a string the message contains.
    # @option attributes [String, Integer, Channel] :in Matches the channel the message was sent in.
    # @option attributes [String, Integer, User] :from Matches the user that sent the message.
    # @option attributes [String] :content Exactly matches the entire content of the message.
    # @option attributes [Time] :after Matches a time after the time the message was sent at.
    # @option attributes [Time] :before Matches a time before the time the message was sent at.
    # @option attributes [Boolean] :private Matches whether or not the channel is private.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [PrivateMessageEvent] The event that was raised.
    # @return [PrivateMessageEventHandler] the event handler that was registered.
    def direct_message(attributes = {}, &block)
      register_event(PrivateMessageEvent, attributes, block)
    end

    # This **event** is raised whenever an invite is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @option attributes [true, false] :temporary Matches whether or not the invite is temporary.
    # @option attributes [Integer, String, User, Member] :creator Matches the user that created the invite.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [InviteCreateEvent] The event that was raised.
    # @return [InviteCreateEventHandler] The event handler that was registered.
    def invite_create(attributes = {}, &block)
      register_event(InviteCreateEvent, attributes, block)
    end

    # This **event** is raised whenever an invite is deleted.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String] :code An invite code to match against.
    # @option attributes [Integer, String, Guild] :guild A guild to match against.
    # @option attributes [Integer, String, Channel] :channel A channel to match against.
    # @yield The block is executed when the event is raised
    # @yieldparam event [InviteDeleteEvent] The event that was raised.
    # @return [InviteDeleteEventHandler] The event handler that was registered.
    def invite_delete(attributes = {}, &block)
      register_event(InviteDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever an interaction event is received.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, Symbol, String] :type The interaction type, can be the integer value or the name
    #   of the key in {Discordrb::Interaction::TYPES}.
    # @option attributes [String, Integer, Guild, nil] :guild The guild where this event was created. `nil` for DM channels.
    # @option attributes [String, Integer, Channel] :channel The channel where this event was created.
    # @option attributes [String, Integer, User] :user The user that triggered this event.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [InteractionCreateEvent] The event that was raised.
    # @return [InteractionCreateEventHandler] The event handler that was registered.
    def interaction_create(attributes = {}, &block)
      register_event(InteractionCreateEvent, attributes, block)
    end

    # This **event** is raised whenever an application command (slash command) is executed.
    # @param name [Symbol, String] The name of the application command this handler is for.
    # @param attributes [Hash] The event's attributes.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ApplicationCommandEvent] The event that was raised.
    # @return [ApplicationCommandEventHandler] The event handler that was registered.
    def application_command(name, attributes = {}, &block)
      name = name.to_sym
      @application_commands ||= {}

      unless block
        @application_commands[name] ||= ApplicationCommandEventHandler.new(attributes, nil)
        return @application_commands[name]
      end

      @application_commands[name] = ApplicationCommandEventHandler.new(attributes, block)
    end

    # This **event** is raised whenever an button interaction is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :custom_id A custom_id to match against.
    # @option attributes [String, Integer, Message] :message The message to filter for.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ButtonEvent] The event that was raised.
    # @return [ButtonEventHandler] The event handler that was registered.
    def button(attributes = {}, &block)
      register_event(ButtonEvent, attributes, block)
    end

    # This **event** is raised whenever an select string interaction is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :custom_id A custom_id to match against.
    # @option attributes [String, Integer, Message] :message The message to filter for.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [StringSelectEvent] The event that was raised.
    # @return [StringSelectEventHandler] The event handler that was registered.
    def string_select(attributes = {}, &block)
      register_event(StringSelectEvent, attributes, block)
    end

    alias_method :select_menu, :string_select

    # This **event** is raised whenever a modal is submitted.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :custom_id A custom_id to match against.
    # @option attributes [String, Integer, Message] :message The message to filter for.
    # @option attributes [String, Integer, Guild, nil] :guild The guild where this event was created. `nil` for DM channels.
    # @option attributes [String, Integer, Channel] :channel The channel where this event was created.
    # @option attributes [String, Integer, User] :user The user that triggered this event.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ModalSubmitEvent] The event that was raised.
    # @return [ModalSubmitEventHandler] The event handler that was registered.
    def modal_submit(attributes = {}, &block)
      register_event(ModalSubmitEvent, attributes, block)
    end

    # This **event** is raised whenever an select user interaction is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :custom_id A custom_id to match against.
    # @option attributes [String, Integer, Message] :message The message to filter for.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [UserSelectEvent] The event that was raised.
    # @return [UserSelectEventHandler] The event handler that was registered.
    def user_select(attributes = {}, &block)
      register_event(UserSelectEvent, attributes, block)
    end

    # This **event** is raised whenever an select role interaction is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :custom_id A custom_id to match against.
    # @option attributes [String, Integer, Message] :message The message to filter for.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [RoleSelectEvent] The event that was raised.
    # @return [RoleSelectEventHandler] The event handler that was registered.
    def role_select(attributes = {}, &block)
      register_event(RoleSelectEvent, attributes, block)
    end

    # This **event** is raised whenever an select mentionable interaction is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :custom_id A custom_id to match against.
    # @option attributes [String, Integer, Message] :message The message to filter for.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [MentionableSelectEvent] The event that was raised.
    # @return [MentionableSelectEventHandler] The event handler that was registered.
    def mentionable_select(attributes = {}, &block)
      register_event(MentionableSelectEvent, attributes, block)
    end

    # This **event** is raised whenever an select channel interaction is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :custom_id A custom_id to match against.
    # @option attributes [String, Integer, Message] :message The message to filter for.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ChannelSelectEvent] The event that was raised.
    # @return [ChannelSelectEventHandler] The event handler that was registered.
    def channel_select(attributes = {}, &block)
      register_event(ChannelSelectEvent, attributes, block)
    end

    # This **event** is raised whenever a message is pinned or unpinned.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Channel] :channel A channel to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ChannelPinsUpdateEvent] The event that was raised.
    # @return [ChannelPinsUpdateEventHandler] The event handler that was registered.
    def channel_pins_update(attributes = {}, &block)
      register_event(ChannelPinsUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever an autocomplete interaction is created.
    # @param name [String, Symbol, nil] An option name to match against.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer] :command_id A command ID to match against.
    # @option attributes [String, Symbol] :subcommand A subcommand name to match against.
    # @option attributes [String, Symbol] :subcommand_group A subcommand group to match against.
    # @option attributes [String, Symbol] :command_name A command name to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [AutocompleteEvent] The event that was raised.
    # @return [AutocompleteEventHandler] The event handler that was registered.
    def autocomplete(name = nil, attributes = {}, &block)
      register_event(AutocompleteEvent, attributes.merge!({ name: name&.to_s }), block)
    end

    # This **event** is raised whenever an application command's permissions are updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer] :command_id A command ID to match against.
    # @option attributes [String, Integer] :application_id An application ID to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ApplicationCommandPermissionsUpdateEvent] The event that was raised.
    # @return [ApplicationCommandPermissionsUpdateEventHandler] The event handler that was registered.
    def application_command_permissions_update(attributes = {}, &block)
      register_event(ApplicationCommandPermissionsUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a user votes on a poll.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, User, Member] :user A user to match against.
    # @option attributes [String, Integer, Channel] :channel A channel to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Message] :message A message to match against.
    # @option attributes [String, Integer, Answer] :answer A poll answer to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [PollVoteAddEvent] The event that was raised.
    # @return [PollVoteAddEventHandler] The event handler that was registered.
    def poll_vote_add(attributes = {}, &block)
      register_event(PollVoteAddEvent, attributes, block)
    end

    # This **event** is raised whenever a user removes their vote on a poll.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, User, Member] :user A user to match against.
    # @option attributes [String, Integer, Channel] :channel A channel to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Message] :message A message to match against.
    # @option attributes [String, Integer, Answer] :answer A poll answer to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [PollVoteRemoveEvent] The event that was raised.
    # @return [PollVoteRemoveEventHandler] The event handler that was registered.
    def poll_vote_remove(attributes = {}, &block)
      register_event(PollVoteRemoveEvent, attributes, block)
    end

    # This **event** is raised whenever a scheduled event is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer] :guild Matches the scheduled event's guild.
    # @option attributes [String, Integer, ScheduledEvent] :id Matches the scheduled event.
    # @option attributes [String, Integer, User, Member] :creator Matches the scheduled event's creator.
    # @option attributes [String, Integer, Channel] :channel Matches the scheduled event's channel.
    # @option attributes [Integer, Symbol, String] :status Matches the status of the scheduled event.
    # @option attributes [Integer, String] :entity_id Matches the entity ID of the scheduled event.
    # @option attributes [Integer, Symbol, String] :entity_type Matches the entity type of the scheduled event.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ScheduledEventCreateEvent] The event that was raised.
    # @return [ScheduledEventCreateEventHandler] the event handler that was registered.
    def scheduled_event_create(attributes = {}, &block)
      register_event(ScheduledEventCreateEvent, attributes, block)
    end

    # This **event** is raised whenever a scheduled event is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild Matches the scheduled event's guild.
    # @option attributes [String, Integer, ScheduledEvent] :id Matches the scheduled event.
    # @option attributes [String, Integer, User, Member] :creator Matches the scheduled event's creator.
    # @option attributes [String, Integer, Channel] :channel Matches the scheduled event's channel.
    # @option attributes [Integer, Symbol, String] :status Matches the status of the scheduled event.
    # @option attributes [Integer, String] :entity_id Matches the entity ID of the scheduled event.
    # @option attributes [Integer, Symbol, String] :entity_type Matches the entity type of the scheduled event.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ScheduledEventUpdateEvent] The event that was raised.
    # @return [ScheduledEventUpdateEventHandler] the event handler that was registered.
    def scheduled_event_update(attributes = {}, &block)
      register_event(ScheduledEventUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a scheduled event is deleted.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild Matches the scheduled event's guild.
    # @option attributes [String, Integer, ScheduledEvent] :id Matches the scheduled event.
    # @option attributes [String, Integer, User, Member] :creator Matches the scheduled event's creator.
    # @option attributes [String, Integer, Channel] :channel Matches the scheduled event's channel.
    # @option attributes [Integer, Symbol, String] :status Matches the status of the scheduled event.
    # @option attributes [Integer, String] :entity_id Matches the entity ID of the scheduled event.
    # @option attributes [Integer, Symbol, String] :entity_type Matches the entity type of the scheduled event.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ScheduledEventDeleteEvent] The event that was raised.
    # @return [ScheduledEventDeleteEventHandler] the event handler that was registered.
    def scheduled_event_delete(attributes = {}, &block)
      register_event(ScheduledEventDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever a user is added to a scheduled event.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild Matches the scheduled event's guild.
    # @option attributes [String, Integer, ScheduledEvent] :scheduled_event Matches the scheduled event.
    # @option attributes [String, Integer, User, Member] :user Matches the user that was added.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ScheduledEventUserAddEvent] The event that was raised.
    # @return [ScheduledEventUserAddEventHandler] the event handler that was registered.
    def scheduled_event_user_add(attributes = {}, &block)
      register_event(ScheduledEventUserAddEvent, attributes, block)
    end

    # This **event** is raised whenever a user is removed from a scheduled event.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild Matches the scheduled event's guild.
    # @option attributes [String, Integer, ScheduledEvent] :scheduled_event Matches the scheduled event.
    # @option attributes [String, Integer, User, Member] :user Matches the user that was removed.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [ScheduledEventUserRemoveEvent] The event that was raised.
    # @return [ScheduledEventUserRemoveEventHandler] the event handler that was registered.
    def scheduled_event_user_remove(attributes = {}, &block)
      register_event(ScheduledEventUserRemoveEvent, attributes, block)
    end

    # This **event** is raised whenever an integration is added to a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Integration] :id An integration to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Application] :application An application to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [IntegrationCreateEvent] The event that was raised.
    # @return [IntegrationCreateEventHandler] The event handler that was registered.
    def integration_create(attributes = {}, &block)
      register_event(IntegrationCreateEvent, attributes, block)
    end

    # This **event** is raised whenever an integration is updated in a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Integration] :id An integration to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Application] :application An application to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [IntegrationUpdateEvent] The event that was raised.
    # @return [IntegrationUpdateEventHandler] The event handler that was registered.
    def integration_update(attributes = {}, &block)
      register_event(IntegrationUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever an integration is removed from a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Integration] :id An integration to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Application] :application An application to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [IntegrationDeleteEvent] The event that was raised.
    # @return [IntegrationDeleteEventHandler] The event handler that was registered.
    def integration_delete(attributes = {}, &block)
      register_event(IntegrationDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever an soundboard sound is created in a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, SoundboardSound] :id A soundboard sound to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, User, Member] :creator A creator to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [SoundboardSoundCreateEvent] The event that was raised.
    # @return [SoundboardSoundCreateEventHandler] The event handler that was registered.
    def soundboard_sound_create(attributes = {}, &block)
      register_event(SoundboardSoundCreateEvent, attributes, block)
    end

    # This **event** is raised whenever an soundboard sound is updated in a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, SoundboardSound] :id A soundboard sound to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, User, Member] :creator A creator to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [SoundboardSoundUpdateEvent] The event that was raised.
    # @return [SoundboardSoundUpdateEventHandler] The event handler that was registered.
    def soundboard_sound_update(attributes = {}, &block)
      register_event(SoundboardSoundUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever an soundboard sound is deleted in a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, SoundboardSound] :id A soundboard sound to match against.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [SoundboardSoundDeleteEvent] The event that was raised.
    # @return [SoundboardSoundDeleteEventHandler] The event handler that was registered.
    def soundboard_sound_delete(attributes = {}, &block)
      register_event(SoundboardSoundDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever an effect is sent to a voice channel the bot is connected to.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Channel] :channel A channel to match against.
    # @option attributes [Integer, String, Member, User] :user A user to match against (you can also pass `:member`).
    # @option attributes [String, Integer, SoundboardSound] :soundboard_sound A soundboard sound to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [VoiceChannelEffectEvent] The event that was raised.
    # @return [VoiceChannelEffectEventEventHandler] The event handler that was registered.
    def voice_channel_effect(attributes = {}, &block)
      register_event(VoiceChannelEffectEvent, attributes, block)
    end

    # This **event** is raised whenever an automod rule is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [String, Integer, AutoModRule] :id An automod rule to match against.
    # @option attributes [String, Integer, User, Member] :creator A creator to match against.
    # @option attributes [Symbol, Integer] :event_type An event type to match against.
    # @option attributes [Symbol, Integer] :trigger_type A trigger type to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [AutoModRuleCreateEvent] The event that was raised.
    # @return [AutoModRuleCreateEventHandler] The event handler that was registered.
    def automod_rule_create(attributes = {}, &block)
      register_event(AutoModRuleCreateEvent, attributes, block)
    end

    # This **event** is raised whenever an automod rule is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [String, Integer, AutoModRule] :id An automod rule to match against.
    # @option attributes [String, Integer, User, Member] :creator A creator to match against.
    # @option attributes [Symbol, Integer] :event_type An event type to match against.
    # @option attributes [Symbol, Integer] :trigger_type A trigger type to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [AutoModRuleUpdateEvent] The event that was raised.
    # @return [AutoModRuleUpdateEventHandler] The event handler that was registered.
    def automod_rule_update(attributes = {}, &block)
      register_event(AutoModRuleUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever an automod rule is deleted.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Regexp] :name A name to match against.
    # @option attributes [String, Integer, AutoModRule] :id An automod rule to match against.
    # @option attributes [String, Integer, User, Member] :creator A creator to match against.
    # @option attributes [Symbol, Integer] :event_type An event type to match against.
    # @option attributes [Symbol, Integer] :trigger_type A trigger type to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [AutoModRuleDeleteEvent] The event that was raised.
    # @return [AutoModRuleDeleteEventHandler] The event handler that was registered.
    def automod_rule_delete(attributes = {}, &block)
      register_event(AutoModRuleDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever an action for an automod rule is executed.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Integer, String, User, Member] :user Matches the user who triggered the auto moderation rule.
    # @option attributes [Integer, String, Guild] :guild Matches the guild where the auto moderation rule was triggered.
    # @option attributes [Integer, String, Channel] :channel Matches the channel where the auto moderation rule was triggered.
    # @option attributes [Integer, String, AutoModRule] :automod_rule Matches the auto moderation rule that was triggered.
    # @option attributes [String, Regexp] :content Matches the content which triggered the auto moderation rule.
    # @option attributes [Symbol, Integer, String] :action_type Matches the type of action that was executed.
    # @option attributes [Symbol, Integer, String] :trigger_type Matches the trigger type of the auto moderation rule that was triggered.
    # @option attributes [String, Regexp] :matched_content Matches the substring that triggered that triggered the auto moderation rule.
    # @option attributes [String, Regexp] :matched_keyword Matches the configured word or phrase that triggered the auto moderation rule.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [AutoModActionEvent] The event that was raised.
    # @return [AutoModActionEventHandler] The event handler that was registered.
    def automod_rule_execution(attributes = {}, &block)
      register_event(AutoModRuleExecutionEvent, attributes, block)
    end

    # This **event** is raised whenever a stage instance is created.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :topic Matches the topic of the stage instance.
    # @option attributes [Integer, String, Guild] :guild Matches the guild of the stage instance.
    # @option attributes [Integer, String, Channel] :channel Matches the channel of the stage instance.
    # @option attributes [Integer, String, ScheduledEvent] :scheduled_event Matches the scheduled event of the stage instance.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [StageInstanceCreateEvent] The event that was raised.
    # @return [StageInstanceCreateEventHandler] the event handler that was registered.
    def stage_instance_create(attributes = {}, &block)
      register_event(StageInstanceCreateEvent, attributes, block)
    end

    # This **event** is raised whenever a stage instance is updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :topic Matches the topic of the stage instance.
    # @option attributes [Integer, String, Guild] :guild Matches the guild of the stage instance.
    # @option attributes [Integer, String, Channel] :channel Matches the channel of the stage instance.
    # @option attributes [Integer, String, ScheduledEvent] :scheduled_event Matches the scheduled event of the stage instance.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [StageInstanceUpdateEvent] The event that was raised.
    # @return [StageInstanceUpdateEventHandler] the event handler that was registered.
    def stage_instance_update(attributes = {}, &block)
      register_event(StageInstanceUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a stage instance is deleted.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Regexp] :topic Matches the topic of the stage instance.
    # @option attributes [Integer, String, Guild] :guild Matches the guild of the stage instance.
    # @option attributes [Integer, String, Channel] :channel Matches the channel of the stage instance.
    # @option attributes [Integer, String, ScheduledEvent] :scheduled_event Matches the scheduled event of the stage instance.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [StageInstanceDeleteEvent] The event that was raised.
    # @return [StageInstanceDeleteEventHandler] the event handler that was registered.
    def stage_instance_delete(attributes = {}, &block)
      register_event(StageInstanceDeleteEvent, attributes, block)
    end

    # This **event** is raised whenever the stickers for a guild are updated.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildStickersUpdateEvent] The event that was raised.
    # @return [GuildStickersUpdateEventHandler] The event handler that was registered.
    def guild_stickers_update(attributes = {}, &block)
      register_event(GuildStickersUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a member is addded to a thread.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Channel] :channel A thread to match against.
    # @option attributes [String, Integer, User, Member] :member A member to match against.
    # @yield The block is executed when the event is raised
    # @yieldparam event [ThreadMemberAddEvent] The event that was raised.
    # @return [ThreadMemberAddEventHandler] The event handler that was registered.
    def thread_member_add(attributes = {}, &block)
      register_event(ThreadMemberAddEvent, attributes, block)
    end

    # This **event** is raised whenever a member is removed from a thread.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Integer, Guild] :guild A guild to match against.
    # @option attributes [String, Integer, Channel] :channel A thread to match against.
    # @option attributes [String, Integer, User, Member] :member A member to match against.
    # @yield The block is executed when the event is raised
    # @yieldparam event [ThreadMemberRemoveEvent] The event that was raised.
    # @return [ThreadMemberRemoveEventHandler] The event handler that was registered.
    def thread_member_remove(attributes = {}, &block)
      register_event(ThreadMemberRemoveEvent, attributes, block)
    end

    # This **event** is raised whenever a join request is created for a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Guild, Integer, String] :guild A guild to match against.
    # @option attributes [Integer, String, User, Member] :user A user to match against.
    # @option attributes [String, Symbol] :status A join request status to match against.
    # @option attributes [Integer, String, JoinRequest] :id A join request ID to match against.
    # @option attributes [Integer, String, User, Member] :reviewed_by A reviewer to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildJoinRequestCreateEvent] The event that was raised.
    # @return [GuildJoinRequestCreateEventHandler] the event handler that was registered.
    def join_request_create(attributes = {}, &block)
      register_event(GuildJoinRequestCreateEvent, attributes, block)
    end

    # This **event** is raised whenever a join request is updated for a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [Guild, Integer, String] :guild A guild to match against.
    # @option attributes [Integer, String, User, Member] :user A user to match against.
    # @option attributes [String, Symbol] :status A join request status to match against.
    # @option attributes [Integer, String, JoinRequest] :id A join request ID to match against.
    # @option attributes [Integer, String, User, Member] :reviewed_by A reviewer to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildJoinRequestUpdateEvent] The event that was raised.
    # @return [GuildJoinRequestUpdateEventHandler] the event handler that was registered.
    def join_request_update(attributes = {}, &block)
      register_event(GuildJoinRequestUpdateEvent, attributes, block)
    end

    # This **event** is raised whenever a join request is deleted for a guild.
    # @param attributes [Hash] The event's attributes.
    # @option attributed [Integer, String, User] :user A user to match against.
    # @option attributes [Guild, Integer, String] :guild A guild to match against.
    # @option attributes [Integer, String, JoinRequest] :id A join request ID to match against.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [GuildJoinRequestDeleteEvent] The event that was raised.
    # @return [GuildJoinRequestDeleteEventHandler] the event handler that was registered.
    def join_request_delete(attributes = {}, &block)
      register_event(GuildJoinRequestDeleteEvent, attributes, block)
    end

    # This **event** is raised for every dispatch received over the gateway, whether supported by discordrb or not.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Symbol, Regexp] :type Matches the event type of the dispatch.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [RawEvent] The event that was raised.
    # @return [RawEventHandler] The event handler that was registered.
    def raw(attributes = {}, &block)
      register_event(RawEvent, attributes, block)
    end

    # This **event** is raised for a dispatch received over the gateway that is not currently handled otherwise by
    # discordrb.
    # @param attributes [Hash] The event's attributes.
    # @option attributes [String, Symbol, Regexp] :type Matches the event type of the dispatch.
    # @yield The block is executed when the event is raised.
    # @yieldparam event [UnknownEvent] The event that was raised.
    # @return [UnknownEventHandler] The event handler that was registered.
    def unknown(attributes = {}, &block)
      register_event(UnknownEvent, attributes, block)
    end

    # Removes an event handler from this container. If you're looking for a way to do temporary events, I recommend
    # {Await}s instead of this.
    # @param handler [Discordrb::Events::EventHandler] The handler to remove.
    def remove_handler(handler)
      clazz = EventContainer.event_class(handler.class)
      @event_handlers ||= {}
      @event_handlers[clazz].delete(handler)
    end

    # Remove an application command handler
    # @param name [String, Symbol] The name of the command handler to remove.
    def remove_application_command_handler(name)
      @application_commands.delete(name)
    end

    # Removes all events from this event handler.
    def clear!
      @event_handlers&.clear
      @application_commands&.clear
    end

    # Adds an event handler to this container. Usually, it's more expressive to just use one of the shorthand adder
    # methods like {#message}, but if you want to create one manually you can use this.
    # @param handler [Discordrb::Events::EventHandler] The handler to add.
    def add_handler(handler)
      clazz = EventContainer.event_class(handler.class)
      @event_handlers ||= {}
      @event_handlers[clazz] ||= []
      @event_handlers[clazz] << handler
    end

    # Adds all event handlers from another container into this one. Existing event handlers will be overwritten.
    # @param container [Module] A module that `extend`s {EventContainer} from which the handlers will be added.
    def include_events(container)
      application_command_handlers = container.instance_variable_get(:@application_commands)
      handlers = container.instance_variable_get :@event_handlers
      return unless handlers || application_command_handlers

      @event_handlers ||= {}
      @event_handlers.merge!(handlers || {}) { |_, old, new| old + new }

      @application_commands ||= {}

      @application_commands.merge!(application_command_handlers || {}) do |_, old, new|
        old.subcommands.merge!(new.subcommands)
        old
      end
    end

    alias_method :include!, :include_events
    alias_method :<<, :add_handler

    # Returns the handler class for an event class type
    # @see #event_class
    # @param event_class [Class] The event type
    # @return [Class] the handler type
    def self.handler_class(event_class)
      class_from_string("#{event_class}Handler")
    end

    # Returns the event class for a handler class type
    # @see #handler_class
    # @param handler_class [Class] The handler type
    # @return [Class, nil] the event type, or nil if the handler_class isn't a handler class (i.e. ends with Handler)
    def self.event_class(handler_class)
      class_name = handler_class.to_s
      return nil unless class_name.end_with? 'Handler'

      EventContainer.class_from_string(class_name[0..-8])
    end

    # Utility method to return a class object from a string of its name. Mostly useful for internal stuff
    # @param str [String] The name of the class
    # @return [Class] the class
    def self.class_from_string(str)
      str.split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
      end
    end

    private

    include Discordrb::Events

    # @return [EventHandler]
    def register_event(clazz, attributes, block)
      handler = EventContainer.handler_class(clazz).new(attributes, block)

      @event_handlers ||= {}
      @event_handlers[clazz] ||= []
      @event_handlers[clazz] << handler

      # Return the handler so it can be removed later
      handler
    end
  end
end
