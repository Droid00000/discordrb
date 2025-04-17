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

    # @return [String] The name of this rule.
    attr_reader :name

    # @return [Symbol] The trigger type of this rule.
    attr_reader :trigger_type

    # @return [Boolean] If this rule is enabled or not.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [Array<Action>] Actions that will execute for this rule.
    attr_reader :actions

    # @return [Array<String>, nil] Regex patterns that can trigger this rule.
    attr_reader :regex_patterns

    # @return [Array<String>, nil] Keywords that can trigger this rule.
    attr_reader :keyword_filters

    # @return [Symbol] The internal preset type used by discord to trigger this rule.
    attr_reader :preset_type

    # @return [Array<String>, nil] Substrings that shouldn't trigger this rule.
    attr_reader :allowed_keywords

    # @return [Integer, nil] The max number of unique mentions allowed per message. Max 50.
    attr_reader :mention_limit

    # @return [Boolean] Whether this rule automatically detects mention raids or not.
    attr_reader :mention_raid
    alias_method :mention_raid?, :mention_raid

    # Wrapper for actions.
    class Actions
      # @return [String, nil] The custom message shown when messages are blocked.
      attr_reader :message

      # @return [Integer, nil] The timeout duration for this action. Max 4 weeks.
      attr_reader :timeout_duration

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @type = data['type']
        @message = data['metatadata']['custom_message']
        @channel_id = data['metatadata']['channel_id']&.to_i
        @timeout_duration = data['metatadata']['duration_seconds']
      end

      # @return [Channel] The channel where alerts will be logged.
      def channel
        @channel ||= @bot.channel(@channel_id)
      end

      # @return [Symbol] The type of action.
      def type
        ACTION_TYPES.key(@type)
      end
    end

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @creator_id = data['creator_id']&.to_i
      @server_id = server || data['guild_id']&.to_i
      @trigger_type = TRIGGER_TYPES.key[data['trigger_type']]

      update_rule_data(data)
    end

    # Get the server this rule originates from.
    # @return [Server] The server this rule comes from.
    def server
      @bot.server(@server)
    end

    # The event type of this rule.
    # @return [Symbol] See {EVENT_TYPES}.
    def event_type
      EVENT_TYPES.key(@event_type)
    end

    # Get the user who created this automod rule.
    # @return [User] The user who created this automod rule.
    def creator
      @creator ||= @bot.user(@creator_id)
    end

    # Get a list of roles that are exempt from this automod rule.
    # @return [Array<Role>] Roles that are ignored by this automod rule.
    def exempt_roles
      @exempt_roles ||= @exempt_role_ids.map { |role| server.role(role) }
    end

    # Get a list of channels that are exempt from this automod rule.
    # @return [Array<Channel>] Channels that are ignored by this automod rule.
    def exempt_channels
      @exempt_channels ||= @exempt_channel_ids.map { |channel| @bot.channel(channel) }
    end

    # Check if something is exempt from thing auto moderation rule.
    # @param object [Integer, String, Role, Channel] The object to check for.
    # @return [true, false] Whether the given object is exempt from this rule or not.
    def exempt?(object)
      (@exempt_channel_ids + @exempt_role_ids).include?(object.resolve_id)
    end

    # Deletes this auto moderation rule.
    # @param reason [String] The reason for deleting this rule.
    def delete(reason = nil)
      API::Server.delete_auto_moderation_rule(@bot.token, @server_id, @id, reason)
      server.delete_automod_rule(@id)
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

    # Update the event type of this rule.
    # @param type [Integer, Symbol] New event type of the rule.
    def event_type=(type)
      update_data(event_type: EVENT_TYPES[type] || type)
    end

    # Set the exempt roles of this rule.
    # @param roles [Array<Role, Integer>] An array of roles or their ID's.
    def exempt_roles=(roles)
      update_data(exempt_roles: roles.map(&:resolve_id))
    end

    # Set the exempt channels of this rule.
    # @param channels [Array<Channel, Integer>] An array of channels or their ID's.
    def exempt_channels=(channels)
      update_data(exempt_channels: channels.map(&:resolve_id))
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
      update_metadata(preset: PRESET_TYPES[type] || type)
    end

    # @param channel [Channel, Integer, String] The channel to send alerts to.
    def alert_channel=(channel)
      update_actions(type: ACTION_TYPES[:send_alert], channel_id: channel&.resolve_id)
    end

    # @param duration [Integer] The timeout duration in seconds.
    def timeout_duration=(duration)
      update_actions(type: ACTION_TYPES[:timeout], duration_seconds: duration)
    end

    # @param message [String] Additional explanation shown to members whenever their message is blocked.
    def block_message=(message)
      update_actions(type: ACTION_TYPES[:block_message], custom_message: message)
    end

    # @param block [true, false] Whether to block members from interacting with other members.
    def block_member=(block)
      update_actions(type: ACTION_TYPES[:block_member])
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
      update_data(trigger_metadata: @metadata.merge!(data))
    end

    # @!visibility private
    # @note for internal use only
    # Update the actions array
    def update_actions(data)
      # Since an automod rule can only have a single action per action
      # type, we know we can operate on that action.
      action = @actions.find { |action| action.to_h[type] = data[:type] }

      # If the action itself doesn't exist yet, this would mean
      # that the user is trying to enable it, so we can create
      # a new action and call it a day here.
      if action.nil?
        @actions << Action.new(data.transform_keys(&:to_s))
      # If the user is passing in nil for the last attribute
      # this would mean that the user is trying to remove the
      # action, so we can just remove the action here.
      elsif data.except(:type).compact.empty?
        @actions = (@actions - [action])
      # If the action isn't nil, we can delete
      # the old action and simply add the new one here.
      elsif !action.nil?
        @actions.delete(action)
        @actions << data
      end

      update_data(actions: @actions.map(&:to_h))
    end

    # @!visibility private
    # @note for internal use only
    # API call to update the rule data with new data
    def update_data(data)
      update_rule_data(JSON.parse(API::Server.modify_auto_moderation_rule(@bot.token, @server.id, @id,
                                                                          data[:name], data[:event_type],
                                                                          data[:trigger_metadata], data[:actions],
                                                                          data[:enabled], data[:exempt_roles], data[:exempt_channels])))
    end

    # @!visibility private
    # @note for internal use only
    # Update the rule data with new data
    def update_data(data)
      @name = data['name']
      @server = data['guild_id']
      @enabled = data['enabled']
      @event_type = data['event_type']
      @exempt_role_ids = data['exempt_roles'].map(&:to_i)
      @exempt_channel_ids = data['exempt_channels'].map(&:to_i)
      @actions = data['actions'].map { |action| Action.new(action, @bot) }

      @metadata = data['trigger_metadata']
      @preset_type = @metadata['preset']
      @regex_patterns = @metadata['regex_patters']
      @keyword_filters = @metadata['keyword_filter']
      @allowed_keywords = @metadata['alow_list']
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

      # @param type [Integer, Symbol] New preset type of the rule.
      def preset_type=(type)
        @metadata[:preset] = PRESET_TYPES[type] || type
      end

      # @param [Array<Role, Integer>] An array of roles or their ID's.
      def exempt_roles=(roles)
        @exempt_roles = roles&.map(&:resolve_id)
      end

      # @param [Array<Channel, Integer>] An array of channels or their ID's.
      def exempt_channels=(channels)
        @exempt_channels = channels&.map(&:resolve_id)
      end

      # @param [Boolean] Whether automatic mention raids should be detected.
      def mention_raid=(enabled)
        @metadata[:mention_raid_protection_enabled] = enabled
      end

      # @param [Array<String>] Array of strings that shouldn't trigger this rule.
      def allowed_keywords=(keywords)
        @metadata[:allow_list] = keywords
      end

      # @param [Array<String>] Regex flavored patterns to trigger this rule.
      def regex_patterns=(patters)
        @metadata[:regex_patterns] = regex
      end

      # @param [Array<String>] Array of strings that should trigger this rule.
      def keyword_filter=(keywords)
        @metadata[:keyword_filter] = keywords
      end

      # @param [Integer] max number of unique mentions allowed per message. Max 50.
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
