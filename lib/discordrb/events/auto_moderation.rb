# frozen_string_literal: true

module Discordrb::Events
  # Generic subclass for auto moderation rule events (create/update/delete)
  class AutoModRuleEvent < Event
    # @return [AutoModRule] the auto moderation rule in question.
    attr_reader :automod_rule

    # @return [Server] the server the automod rule is from.
    attr_reader :server

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @automod_rule = @server.automod_rule(data['id'].to_i)
    end
  end

  # Raised when an auto moderation rule is created.
  class AutoModRuleCreateEvent < AutoModRuleEvent; end

  # Raised when an auto moderation rule is updated.
  class AutoModRuleUpdateEvent < AutoModRuleEvent; end

  # Raised when an auto moderation rule is deleted.
  class AutoModRuleDeleteEvent < AutoModRuleEvent
    # Override the initializer, since the event provides the rule,
    #   but it won't exist in the cache because it was just deleted.
    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @automod_rule = Discordrb::AutoModRule.new(data, bot, server)
    end
  end

  # Event handler for generic auto-moderation rule events.
  class AutoModRuleEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a? AutoModRuleEvent

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e
        end,

        matches_all(@attributes[:name], event.automod_rule.name) do |a, e|
          case a
          when String, Symbol
            a.to_s == e
          when Regexp
            a.match?(e)
          end
        end,

        matches_all(@attributes[:automod_rule], event.automod_rule) do |a, e|
          a.resolve_id == e
        end,

        matches_all(@attributes[:creator], event.automod_rule.creator) do |a, e|
          a.resolve_id == e
        end,

        matches_all(@attributes[:event_type], event.automod_rule.event_type) do |a, e|
          case a
          when Symbol, String
            e == Discordrb::AutoModRule::EVENT_TYPES[a.to_sym]
          when Integer
            e == a
          end
        end,

        matches_all(@attributes[:trigger_type], event.automod_rule.trigger_type) do |a, e|
          case a
          when Symbol, String
            e == Discordrb::AutoModRule::Trigger::TYPES[a.to_sym]
          when Integer
            e == a
          end
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :AUTO_MODERATION_RULE_CREATE events.
  class AutoModRuleCreateEventHandler < AutoModRuleEventHandler; end

  # Event handler for :AUTO_MODERATION_RULE_UPDATE events.
  class AutoModRuleUpdateEventHandler < AutoModRuleEventHandler; end

  # Event handler for :AUTO_MODERATION_RULE_DELETE events.
  class AutoModRuleDeleteEventHandler < AutoModRuleEventHandler; end

  # This event is raised whenever an automod rule is triggered.
  class AutoModActionEvent < Event
    # @!visibility private
    attr_reader :server_id, :rule_id, :user_id, :channel_id

    # @return [AutoModRule::Action] the action which was taken.
    attr_reader :action

    # @return [Integer] Trigger type of the rule which was triggered.
    attr_reader :trigger_type

    # @return [String] User generated content that triggered the rule.
    attr_reader :content

    # @return [String, nil] Word or phrase that triggered the rule.
    attr_reader :matched_keyword

    # @return [String, nil] The substring in content that triggered the rule.
    attr_reader :matched_content

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server_id = data['guild_id'].to_i
      @rule_id = data['rule_id'].to_i
      @user_id = data['user_id'].to_i
      @channel_id = data['channel_id']&.to_i
      @message_id = data['message_id']&.to_i
      @alert_message_id = data['alert_system_message_id']&.to_i

      @action = Discordrb::AutoModRule::Action.new(data['action'], bot)
      @trigger_type = data['trigger_type']
      @content = data['content']
      @matched_keyword = data['matched_keyword']
      @matched_content = data['matched_content']
    end

    # @return [Server] the server this event originates from.
    def server
      @bot.server(@server_id)
    end

    # @return [Channel] channel in which user content was posted.
    def channel
      @bot.channel(@channel_id) if @channel_id
    end

    # @return [AutoModRule] the rule that was triggered for this event.
    def automod_rule
      @automod_rule ||= server.automod_rule(@rule_id)
    end

    # @return [User, Member] the user or member which generated the content that triggered the rule.
    def user
      server.member(@user_id) || @bot.user(@user_id)
    end

    alias_method :member, :user

    # @return [Message, nil] message which contants user generated content that triggered this rule.
    def message
      @message_id ? (@message ||= channel.load_message(@message_id)) : nil
    end

    # @return [Message, nil] System auto moderation message posted as a result of this action.
    def alert_message
      @alert_channel ||= automod_rule.actions.find(&:send_alert_message?)&.alert_channel

      @alert_channel&.load_message(@alert_message_id) if @alert_message_id
    end
  end

  # Event handler for auto-moderation rule execution events.
  class AutoModActionEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a? AutoModActionEvent

      [

        matches_all(@attributes[:user], event.user_id) do |a, e|
          a.resolve_id == e
        end,

        matches_all(@attributes[:server], event.server_id) do |a, e|
          a.resolve_id == e
        end,

        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a.resolve_id == e
        end,

        matches_all(@attributes[:automod_rule], event.rule_id) do |a, e|
          a.resolve_id == e
        end,

        matches_all(@attributes[:content], event.content) do |a, e|
          case a
          when String
            e == a
          when Regexp
            e ? a.match?(e) : false
          end
        end,

        matches_all(@attributes[:trigger_type], event.trigger_type) do |a, e|
          case a
          when Symbol, String
            e == Discordrb::AutoModRule::Trigger::TYPES[a.to_sym]
          when Integer
            e == a
          end
        end,

        matches_all(@attributes[:matched_content], event.matched_content) do |a, e|
          case a
          when String
            e == a
          when Regexp
            e ? a.match?(e) : false
          end
        end,

        matches_all(@attributes[:matched_keyword], event.matched_keyword) do |a, e|
          case a
          when String
            e == a
          when Regexp
            e ? a.match?(e) : false
          end
        end,

        matches_all(@attributes[:event_type], event.automod_rule.event_type) do |a, e|
          case a
          when Symbol, String
            e == Discordrb::AutoModRule::EVENT_TYPES[a.to_sym]
          when Integer
            e == a
          end
        end
      ].reduce(true, &:&)
    end
  end
end
