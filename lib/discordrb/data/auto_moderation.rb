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

    # @return [Server] The server this rule originates from.
    attr_reader :server

    # @return [String] The name of this rule.
    attr_reader :name

    # @return [User, Member, nil] The creator of this rule.
    attr_reader :creator

    # @return [Symbol] The event type of this rule.
    attr_reader :event_type

    # @return [Symbol] The trigger type of this rule.
    attr_reader :trigger_type

    # @return [Boolean] If this rule is enabled or not.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [Array<Role>] Roles exempt from this rule.
    attr_reader :exempt_roles

    # @return [Array<Channel>] Channels exempt from this rule.
    attr_reader :exempt_channels

    # @return [Array<Action>] Actions that will execute for this rule.
    attr_reader :actions

    # @return [Array<String>] Regex patterns that can trigger this rule.
    attr_reader :regex_patterns

    # @return [Array<String>] Keywords that can trigger this rule.
    attr_reader :keyword_filters

    # @return [Symbol] The internal preset type used by discord to trigger this rule.
    attr_reader :preset_type

    # @return [Array<String>] Substrings that shouldn't trigger this rule.
    attr_reader :allowed_keywords

    # @return [Integer] The max number of unique mentions allowed per message. Max 50.
    attr_reader :mention_limit

    # @return [Boolean] Whether this rule automatically detects mention raids or not.
    attr_reader :mention_raid
    alias_method :mention_raid?, :mention_raid

    # Wrapper for actions.
    class Actions
      # @return [Symbol] The type of action.
      attr_reader :type

      # @return [String, nil] The custom message shown when messages are blocked.
      attr_reader :message

      # @return [Channel, nil] The channel where alerts are logged.
      attr_reader :channel

      # @return [Time, nil] The timeout duration for this action. Max 4 weeks.
      attr_reader :timeout_duration

      # @!visibility private
      def initialize(data, bot)
        @type = ACTION_TYPES.invert[data['type']]
        @message = data['metatadata']['custom_message'] if data['metatadata']['custom_message']
        @channel = bot.channel(data['metatadata']['channel_id']) if data['metatadata']['channel_id']
        @timeout_duration = Time.at(data['metatadata']['duration_seconds']) if data['metatadata']['duration_seconds']
      end
    end

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot

      @id = data['id'].to_i
      @name = data['name']
      @enabled = data['enabled']
      @event_type = EVENT_TYPES.invert[data['event_type']]
      @trigger_type = TRIGGER_TYPES.invert[data['trigger_type']]
      @server = server || bot.server(data['guild_id'])
      @creator = bot.member(@server, data['creator_id']) || bot.user(data['creator_id'])
      @actions = data['actions'].map { |action| Action.new(action, bot) }
      @exempt_roles = data['exempt_roles'].map { |id| @server.role(id) }
      @exempt_channels = data['exempt_channels'].map { |id| bot.channel(id, @server) }

      @metadata = data['trigger_metadata']
      @regex_patterns = @metadata['regex_patterns']
      @keyword_filter = @metadata['keyword_filter']
      @allowed_keywords = @metadata['allow_list']
      @mention_limit = @metadata['mention_total_limit']
      @preset_type = TRIGGER_PRESETS.invert[@metadata['preset']]
      @mention_raid = @metadata['mention_raid_protection_enabled']
    end

    # Deletes this auto moderation rule.
    # @param reason [String] The reason for deleting this rule.
    def delete(reason = nil)
      API::Server.delete_auto_moderation_rule(@bot.token, @server.id, @id, reason)
      @server.delete_automod_rule(@id)
    end

    # Update the name of this rule.
    # @param name [String] New name of the rule.
    def name=(name)
      update_rule_data(name: name)
    end

    # Update whether this rule is enabled or not.
    # @param enabled [Boolean] Whether this rule should be enabled or not.
    def enabled=(enabled)
      update_rule_data(enabled: enabled)
    end

    # Update the event type of this rule.
    # @param type [Integer, Symbol] New event type of the rule.
    def event_type=(type)
      update_rule_data(event_type: EVENT_TYPES.invert[type] || type)
    end

    # Set the exempt roles of this rule.
    # @param roles [Array<Role, Integer>] An array of roles or their ID's.
    def exempt_roles=(roles)
      update_rule_data(exempt_roles: roles.map(&:resolve_id))
    end

    # Set the exempt channels of this rule.
    # @param channels [Array<Channel, Integer>] An array of channels or their ID's.
    def exempt_channels=(channels)
      update_rule_data(exempt_channels: channels.map(&:resolve_id))
    end

    # @param enabled [Boolean] Whether automatic mention raids should be detected.
    def mention_raid=(enabled)
      update_metadata(enabled: enabled)
    end

    # @param keywords [Array<String>] Array of strings that shouldn't trigger this rule.
    def allowed_keywords=(keywords)
      update_metadata(allow_list: keywords)
    end

    # @param regex [Array<String>] Regex flavored patterns to trigger this rule.
    def regex_patterns=(regex)
      update_metadata(regex_patterns: regex)
    end

    # @param keywords [Array<String>] Array of strings that should trigger this rule.
    def keyword_filter=(keywords)
      update_metadata(keyword_filter: keywords)
    end

    # @param limit [Integer] max number of unique mentions allowed per message. Max 50.
    def mention_limit=(limit)
      update_metadata(mention_total_limit: limit)
    end

    # @param type [Integer, Symbol] New preset type of the rule.
    def preset_type=(type)
      update_metadata(preset: PRESET_TYPES.invert[type] || type)
    end

    # The inspect method is overwritten to give more useful output.
    def inspect
      "server=#{@server.inspect} id=#{@id} name=#{@name} mention_limit=#{@mention_limit} regex_patterns=#{@regex_patterns} creator=#{@creator.inspect} preset_type=#{@preset_type} event_type=#{@event_type}"
    end

    private

    # @!visibility private
    # @note for internal use only
    # Update the metadata object
    def update_metadata(data)
      data = @metadata[data.first[0].to_s] = data.first[1]
      update_rule_data(trigger_metadata: data)
    end

    # @!visibility private
    # @note for internal use only
    # API call to update the rule data with new data
    def update_rule_data(data)
      update_data(API::Server.modify_auto_moderation_rule(@bot.token, @server.id, @id,
                                                          data[:name], data[:event_type],
                                                          data[:trigger_metadata], data[:actions],
                                                          data[:enabled], data[:exempt_roles], data[:exempt_channels]))
    end

    # @!visibility private
    # @note for internal use only
    # Update the rule data with new data
    def update_data(data)
      data = JSON.parse(data)

      @name = data['name']
      @enabled = data['enabled']
      @event_type = EVENT_TYPES.invert[data['event_type']]
      @creator = bot.member(@server, data['creator_id']) || @bot.user(data['creator_id'])
      @actions = data['actions'].map { |action| Action.new(action, @bot) }
      @exempt_roles = data['exempt_roles'].map { |id| @server.role(id) }
      @exempt_channels = data['exempt_channels'].map { |id| bot.channel(id, @server) }

      @metadata = data['trigger_metadata']
      @regex_patterns = @metadata['regex_patters']
      @keyword_filters = @metadata['keyword_filter']
      @allowed_keywords = @metadata['alow_list']
      @mention_limit = @metadata['mention_total_limit']
      @preset_type = TRIGGER_PRESETS.invert[@metadata['preset']]
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

      # @param name [String]
      # @param event_type [Integer]
      # @param trigger_type [Integer]
      # @param metadata [Hash]
      # @param actions [Array<Hash>]
      # @param enabled [Boolean]
      # @param exempt_roles [Array<Role>]
      # @param exempt_channels[Array<Channel>]
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

      # Set the exempt roles of this rule.
      # @param roles [Array<Role, Integer>] An array of roles or their ID's.
      def exempt_roles=(roles)
        @exempt_roles = roles.map(&:resolve_id)
      end

      # Set the exempt channels of this rule.
      # @param channels [Array<Channel, Integer>] An array of channels or their ID's.
      def exempt_channels=(channels)
        @exempt_channels = channels.map(&:resolve_id)
      end

      # @param enabled [Boolean] Whether automatic mention raids should be detected.
      def mention_raid=(enabled)
        @metadata[:mention_raid_protection_enabled] = enabled
      end

      # @param keywords [Array<String>] Array of strings that shouldn't trigger this rule.
      def allowed_keywords=(keywords)
        @metadata[:allow_list] = keywords
      end

      # @param regex [Array<String>] Regex flavored patterns to trigger this rule.
      def regex_patterns=(regex)
        @metadata[:regex_patterns] = regex
      end

      # @param keywords [Array<String>] Array of strings that should trigger this rule.
      def keyword_filter=(keywords)
        @metadata[:keyword_filter] = keywords
      end

      # @param limit [Integer] max number of unique mentions allowed per message. Max 50.
      def mention_limit=(limit)
        @metadata[:mention_total_limit] = limit
      end

      # @param type [Integer, Symbol] New preset type of the rule.
      def preset_type=(type)
        @metadata[:preset] = PRESET_TYPES[type] || type
      end

      # Add an action that'll be executed when this rule is triggered.
      # Some of these fields can be ommited based on the type of action.
      # @param type [Symbol, Integer] The type of action to be executed.
      # @param channel [Channel, Integer, String] Channel where alerts should be logged.
      # @param timeout_duration [Integer] The timeout duration of seconds. Max 2419200 seconds.
      # @param custom_message [String] 150 character message to be shown whenever a message is blocked.
      def add_action(type:, channel: nil, timeout_duration: nil, custom_message: nil)
        type = ACTION_TYPES[type] || type

        @metadata << { type: type, metadata: { channel_id: channel&.map(&:resolve_id), duration_seconds: timeout_duration, custom_message: custom_message }.compact }
      end

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
        }.to_h
      end
    end
  end
end
