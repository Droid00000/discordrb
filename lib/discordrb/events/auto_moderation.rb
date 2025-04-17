# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Raised when an auto-moderation rule is created.
  class AutoModerationRuleCreateEvent < Event
    # @return [AutoModerationRule] the rule in question.
    attr_reader :auto_moderation_rule
    alias_method :rule, :auto_moderation_rule

    # @!attribute [r] id
    #   @see AutoModerationRule#id
    # @!attribute [r] name
    #   @see AutoModerationRule#name
    # @!attribute [r] server
    #   @see AutoModerationRule#server
    # @!attribute [r] event_type
    #   @see AutoModerationRule#event_type
    # @!attribute [r] trigger_type
    #   @see AutoModerationRule#trigger_type
    # @!attribute [r] enabled
    #   @see AutoModerationRule#enabled
    # @!attribute [r] actions
    #   @see AutoModerationRule#actions
    # @!attribute [r] regex_patterns
    #   @see AutoModerationRule#regex_patterns
    # @!attribute [r] keyword_filters
    #   @see AutoModerationRule#keyword_filters
    # @!attribute [r] preset_type
    #   @see AutoModerationRule#preset_type
    # @!attribute [r] allowed_keywords
    #   @see AutoModerationRule#allowed_keywords
    # @!attribute [r] mention_limit
    #   @see AutoModerationRule#mention_limit
    # @!attribute [r] mention_raid
    #   @see AutoModerationRule#mention_raid
    # @!attribute [r] creator
    #   @see AutoModerationRule#creator
    # @!attribute [r] exempt_roles
    #   @see AutoModerationRule#exempt_roles
    # @!attribute [r] exempt_channels
    #   @see AutoModerationRule#exempt_channels
    delegate :id, :name, :server, :event_type, :trigger_type, :enabled, :enabled?, :actions,
             :regex_patterns, :keyword_filters, :preset_type, :allowed_keywords, :mention_limit,
             :mention_raid, :mention_raid?, :creator, :exempt_roles, :exempt_channels, to: :auto_moderation_rule

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @auto_moderation_rule = @bot.servers[data['guild_id'].to_i].auto_moderation_rule(data['id'].to_i)
    end
  end

  # Raised when an auto-moderation rule is updated.
  class AutoModerationRuleUpdateEvent < AutoModerationRuleCreateEvent; end

  # Raised when an auto-moderation rule is deleted.
  class AutoModerationRuleUpdateEvent < AutoModerationRuleDeleteEvent; end

  # Raised when an auto-moderation rule is triggered and an action is executed.
  class AutoModerationActionExecutionEvent < Event
    # @return [Integer]
    attr_reader :rule_id

    # @return [Integer]
    attr_reader :user_id

    # @return [Integer]
    attr_reader :server_id

    # @return [Integer, nil]
    attr_reader :channel_id

    # @return [Integer, nil]
    attr_reader :message_id

    # @return [Integer, nil]
    attr_reader :alert_message_id

    # @return [Action]
    attr_reader :action

    # @return [Symbol]
    attr_reader :trigger_type

    # @return [String, nil]
    attr_reader :content

    # @return [String, nil]
    attr_reader :matched_keyword

    # @return [String, nil]
    attr_reader :matched_content

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @rule_id = data['rule_id']&.to_i
      @user_id = data['user_id']&.to_i
      @server_id = data['guild_id']&.to_i
      @channel_id = data['channel_id']&.to_i
      @message_id = data['message_id']&.to_i
      @alert_message_id = data['alert_system_message_id']&.to_i

      @content = data['content']
      @matched_keyword = data['matched_keyword']
      @matched_content = data['matched_content']

      @action = AutoModerationRule::Action.new(data['action'], bot)
      @trigger_type = AutoModerationRule::TRIGGER_TYPES[data['rule_trigger_type']]
    end

    # @return [Server] The server where this action was executed.
    def server
      @server ||= @bot.server(@server_id)
    end

    # @return [Member, User] The user that triggered this rule.
    def user
      @user ||= (server.member(@user_id) || @bot.user(@user_id))
    end

    alias_method :member, :user

    # @return [AutoModerationRule] The automod rule that was triggered.
    def auto_moderation_rule
      @auto_moderation_rule ||= server.auto_moderation_rule(@rule_id)
    end

    alias_method :rule, :auto_moderation_rule

    # @return [Channel, nil] the channel in which user content was posted.
    def channel
      return unless @channel_id

      @channel ||= @bot.channel(@channel_id)
    end

    # @return [Message, nil] The user message which matched content belongs to.
    def message
      return unless @message_id

      @message ||= channel.load_message(@message_id)
    end

    # @return [Message, nil] System auto moderation message because of this action.
    def alert_message
      return unless @alert_message_id

      @alert_message ||= @action.channel.load_message(@alert_message_id)
    end
  end
end
