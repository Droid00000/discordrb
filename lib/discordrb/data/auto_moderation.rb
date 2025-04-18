# frozen_string_literal: true

module Discordrb
  # An Auto moderation rule for a server.
  class AutoModerationRule
    include IDObject

    # Map of trigger types.
    TRIGGER_TYPES = {
      keyword: 1,
      spam: 3,
      keyword_preset: 4,
      mention_spam: 5,
      member_profile: 6
    }.freeze

    # Map of action types.
    ACTION_TYPES = {
      block_message: 1,
      send_alert: 2,
      timeout: 3,
      block_member: 4
    }.freeze

    # Map of preset types.
    PRESET_TYPES = {
      profanity: 1,
      sexual_content: 2,
      slurs: 3
    }.freeze

    # Map of event types.
    EVENT_TYPES = {
      message: 1,
      member: 2
    }.freeze

    # @return [String] the name of this rule.
    attr_reader :name

    # @return [Server] the server this rule originates from.
    attr_reader :server

    # @return [Symbol] the trigger type of this rule See {TRIGGER_TYPES}.
    attr_reader :trigger_type

    # @return [Boolean] if this rule is enabled or not.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [Array<Action>] actions that will execute for this rule.
    attr_reader :actions

    # @return [Array<String>, nil] regex patterns that can trigger this rule.
    attr_reader :regex_patterns

    # @return [Array<String>, nil] keywords that can trigger this rule.
    attr_reader :keyword_filter

    # @return [Symbol] The internal preset type used by discord to trigger this rule.
    attr_reader :preset_type

    # @return [Array<String>, nil] substrings that shouldn't trigger this rule.
    attr_reader :allowed_keywords

    # @return [Integer, nil] the max number of unique mentions allowed per message. Max 50.
    attr_reader :mention_limit

    # @return [true, false] whether this rule automatically detects mention raids or not.
    attr_reader :mention_raid
    alias_method :mention_raid?, :mention_raid

    # Wrapper for actions.
    class Action
      # @return [String, nil] the custom message shown when messages are blocked.
      attr_reader :message

      # @return [Integer, nil] the timeout duration for this action. Max 4 weeks.
      attr_reader :timeout_duration

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @type = data['type']
        @message = data['metatadata']['custom_message']
        @channel_id = data['metatadata']['channel_id']&.to_i
        @timeout_duration = data['metatadata']['duration_seconds']
      end

      # @return [Channel] the channel where alerts will be logged.
      def channel
        @channel_id ? (@channel ||= @bot.channel(@channel_id)) : nil
      end

      # @return [Symbol] the type of action.
      def type
        ACTION_TYPES.key(@type)
      end
    end

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['id'].to_i
      @creator_id = data['creator_id']&.to_i
      @trigger_type = TRIGGER_TYPES.key[data['trigger_type']]

      update_rule_data(data)
    end

    # @return [Symbol] The event type of this rule see {EVENT_TYPES}.
    def event_type
      EVENT_TYPES.key(@event_type)
    end

    # @return [Member, User] The user who created this automod rule.
    def creator
      @creator ||= (server.member(@creator_id) || @bot.user(@creator_id))
    end

    # @return [Array<Role>] Get a list of roles that are exempt from this rule.
    def exempt_roles
      @exempt_roles ||= @exempt_role_ids.map { |role| server.role(role) }
    end

    # @return [Array<Channel>] Get a list of channels that are exempt from this rule.
    def exempt_channels
      @exempt_channels ||= @exempt_channel_ids.map { |chan| @bot.channel(chan) }
    end

    # Check if something is exempt from this auto moderation rule.
    # @param thing [Integer, String, Role, Channel, Member] The object to check for.
    # @return [true, false] Whether the given object is exempt from this rule or not.
    def exempt?(thing)
      if thing.is_a?(Member)
        member.permission?(:manage_server) || member.roles.any?(exempt_roles)
      else
        (exempt_channels + exempt_roles).map(&:id).include?(object.resolve_id)
      end
    end

    # Deletes this auto moderation rule.
    # @param reason [String] The reason for deleting this rule.
    def delete(reason = nil)
      API::Server.delete_auto_moderation_rule(@bot.token, server.id, id, reason)
      server.delete_automod_rule(id)
    end

    # Update the name of this rule.
    # @param name [String] New name of the rule.
    def name=(name)
      update_data(name: name)
    end

    # Update whether this rule is enabled or not.
    # @param enabled [Boolean] Whether this rule should be enabled or not.
    def enabled=(enabled)
      update_data(enabled: enabled)
    end

    # @param type [Integer, Symbol] The event type of the rule.
    def event_type=(type)
      update_data(event_type: EVENT_TYPES[type] || type)
    end

    # @param roles [Array<Role>] Roles that are exempt from this rule.
    def exempt_roles=(roles)
      update_data(exempt_roles: roles.map(&:resolve_id))
    end

    # @param channels [Array<Channel>] Channels that are exempt from this rule.
    def exempt_channels=(channels)
      update_data(exempt_channels: channels.map(&:resolve_id))
    end

    # @param keywords [Array<String>] Array of strings that shouldn't trigger this rule.
    def allowed_keywords=(keywords)
      update_data(allow_list: keywords)
    end

    # @param patterns [Array<String>] Regex patterns that can trigger this rule.
    def regex_patterns=(patterns)
      update_data(regex_patterns: patterns)
    end

    # @param keywords [Array<String>] Array of keyword that can trigger this rule.
    def keyword_filter=(keywords)
      update_data(keyword_filter: keywords)
    end

    # @param mention_limit [Integer] max number of unique mentions allowed per message. Max 50.
    def mention_limit=(mention_limit)
      update_data(mention_total_limit: mention_limit)
    end

    # @param type [Integer, Symbol] New preset type of the rule.
    def preset_type=(type)
      update_data(preset: PRESET_TYPES[type] || type)
    end

    # @param enabled [true, false] Whether automatic mention raids should be detected for this rule.
    def mention_raid=(enabled)
      update_data(mention_raid_protection_enabled: enabled)
    end

    private

    # @!visibility private
    # @note for internal use only
    # API call to update the rule data with new data
    def update_data(data)
      data = { trigger_metadata: @metatadata.merge(data) } if data.keys.any?(@metatadata.keys.map(&:to_sym))

      update_rule_data(JSON.parse(API::Server.modify_auto_moderation_rule(@bot.token, @server.id, @id,
                                                                          data[:name], data[:event_type],
                                                                          data[:trigger_metadata], data[:actions],
                                                                          data[:enabled], data[:exempt_roles], data[:exempt_channels])))
    end

    # @!visibility private
    # @note for internal use only
    # Update the rule data with new data
    def update_rule_data(data)
      @name = data['name']
      @enabled = data['enabled']
      @event_type = data['event_type']
      @exempt_roles = data['exempt_roles'].map(&:to_i)
      @exempt_channels = data['exempt_channels'].map(&:to_i)
      @actions = data['actions'].map { |action| Action.new(action, @bot) }

      @metadata = data['trigger_metadata']
      @preset_type = @metadata['preset']
      @regex_patterns = @metadata['regex_patterns']
      @keyword_filters = @metadata['keyword_filter']
      @allowed_keywords = @metadata['allow_list']
      @mention_limit = @metadata['mention_total_limit']
      @mention_raid = @metadata['mention_raid_protection_enabled']
    end

    # Builder class to easily create rules.
    class Builder
      # @!attribute name
      # @return [String] Sets the rule name.
      attr_writer :name

      # @!attribute enabled
      # @return [Boolean] Whether this rule should be enabled.
      attr_writer :enabled

      # @!visibility private
      def initialize(name: nil, event_type: nil, trigger_type: nil, metadata: {}, actions: [], enabled: true, exempt_roles: nil, exempt_channels: nil)
        @name = name
        @event_type = event_type
        @trigger_type = trigger_type
        @trigger_metadata = metadata
        @actions = actions
        @enabled = enabled
        @exempt_roles = exempt_roles
        @exempt_channels = exempt_channels
      end

      # Set the event type of this rule.
      # @param type [Integer, Symbol] New event type of the rule.
      def event_type=(type)
        @event_type = EVENT_TYPES[type] || type
      end

      # Set the trigger type of this rule.
      # @param type [Integer, Symbol] New trigger type of the rule.
      def trigger_type=(type)
        @trigger_type = TRIGGER_TYPES[type] || type
      end

      # @param type [Integer, Symbol] New preset type of the rule.
      def preset_type=(type)
        @metadata[:preset] = PRESET_TYPES[type] || type
      end

      # @param roles [Array<Role, Integer>] An array of roles or their ID's.
      def exempt_roles=(roles)
        @exempt_roles = roles&.map(&:resolve_id)
      end

      # @param channels [Array<Channel, Integer>] An array of channels or their ID's.
      def exempt_channels=(channels)
        @exempt_channels = channels&.map(&:resolve_id)
      end

      # @param enabled [Boolean] Whether automatic mention raids should be detected.
      def mention_raid=(enabled)
        @metadata[:mention_raid_protection_enabled] = enabled
      end

      # @param keywords [Array<String>] Array of strings that shouldn't trigger this rule.
      def allowed_keywords=(keywords)
        @metadata[:allow_list] = keywords
      end

      # @param patterns [Array<String>] Regex flavored patterns to trigger this rule.
      def regex_patterns=(patterns)
        @metadata[:regex_patterns] = patterns
      end

      # @param keywords [Array<String>] Array of strings that should trigger this rule.
      def keyword_filter=(keywords)
        @metadata[:keyword_filter] = keywords
      end

      # @param limit [Integer] max number of unique mentions allowed per message. Max 50.
      def mention_limit=(limit)
        @metadata[:mention_total_limit] = limit
      end

      # Add an action that'll be executed when this rule is triggered.
      # Some of these fields can be ommited based on the type of action.
      # @param type [Symbol, Integer] The type of action to be executed.
      # @param channel [Channel, Integer, String] Channel where alerts should be logged.
      # @param timeout_duration [Integer] The timeout duration of seconds. Max 2419200 seconds.
      # @param custom_message [String] 150 character message to be shown whenever a message is blocked.
      def add_action(type:, channel: nil, timeout_duration: nil, custom_message: nil)
        metadata = { channel_id: channel&.resolve_id, duration_seconds: timeout_duration, custom_message: custom_message }

        @actions << { type: (ACTION_TYPES[type] || type), metadata: metadata.compact }
      end

      alias_method :action, :add_action

      # @!visibility private
      # Converts the builder into a hash that can be sent to Discord.
      def to_h
        {
          name: @name,
          event_type: @event_type,
          trigger_type: @trigger_type,
          trigger_metadata: @metadata,
          actions: @actions,
          enabled: @enabled,
          exempt_roles: @exempt_roles,
          exempt_channels: @exempt_channels
        }.compact
      end
    end
  end
end
