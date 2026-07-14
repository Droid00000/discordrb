# frozen_string_literal: true

module Discordrb
  # Generic parent module for audit logs.
  module AuditLog
    # A set of entities referenced by an audit log entry.
    class Entities
      # @return [Guild] the guild that the entities are from.
      attr_reader :guild

      # @!visibility private
      def initialize(data, guild, bot)
        @bot = bot
        @guild = guild
        process_users(data[:users])
        @thread_data = data[:threads]
        @webhook_data = data[:webhooks]
        @integration_data = data[:integrations]
        @automod_data = data[:auto_moderation_rules]
        @scheduled_event_data = data[:guild_scheduled_events]
        @application_command_data = data[:application_commands]
      end

      # @!visibility private
      names = %i[
        users
        threads
        webhooks
        integrations
        automod_rules
        scheduled_events
        application_commands
      ]

      # @!attribute [r] users
      #   @return [Hash<Integer => User>] a mapping of user IDs to users.
      # @!attribute [r] threads
      #   @return [Hash<Integer => Channel>] a mapping of thread IDs to threads.
      # @!attribute [r] webhooks
      #   @return [Hash<Integer => Webhook>] a mapping of webhook IDs to webhooks.
      # @!attribute [r] integrations
      #   @return [Hash<Integer => Integration>] a mapping of integration IDs to integrations.
      # @!attribute [r] automod_rules
      #   @return [Hash<Integer => AutoModRule>] a mapping of automod rule IDs to automod rules.
      # @!attribute [r] scheduled_events
      #   @return [Hash<Integer => ScheduledEvent>] a mapping of scheduled event IDs to scheduled events.
      # @!attribute [r] application_commands
      #   @return [Hash<Integer => ApplicationCommand>] a mapping of application command IDs to application commands.
      names.each do |name|
        define_method(name) do
          ivar_name = :"@#{name}"
          data = instance_variable_get(ivar_name)
          return data if data

          self.__send__(:"process_#{name}")
          instance_variable_get(ivar_name)
        end
      end

      private

      # @!visibility private
      def process_users(users)
        @users = {}

        users&.each do |user|
          user = @bot.ensure_user(user)
          @users[user.id] = user
        end
      end

      # @!visibility private
      def process_threads
        @threads = {}

        @thread_data&.each do |thread|
          thread = Channel.new(thread, @bot, @guild)
          @threads[thread.id] = thread
        end

        @thread_data = nil
      end

      # @!visibility private
      def process_webhooks
        @webhooks = {}

        @webhook_data&.each do |webhook|
          webhook = Webhook.new(webhook, @bot)
          @webhooks[webhook.id] = webhook
        end

        @webhook_data = nil
      end

      # @!visibility private
      def process_integrations
        @integrations = {}

        @integration_data&.each do |integration|
          integration = Integration.new(integration, @guild, @bot)
          @integrations[integration.id] = integration
        end

        @integration_data = nil
      end

      # @!visibility private
      def process_automod_rules
        @automod_rules = {}

        @automod_data&.each do |rule|
          rule = AutoModRule.new(rule, @guild, @bot)
          @automod_rules[rule.id] = rule
        end

        @automod_data = nil
      end

      # @!visibility private
      def process_scheduled_events
        @scheduled_events = {}

        @scheduled_event_data&.each do |event|
          event = ScheduledEvent.new(event, @guild, @bot)
          @scheduled_events[event.id] = event
        end

        @scheduled_event_data = nil
      end

      # @!visibility private
      def process_application_commands
        @application_commands = {}

        @application_command_data&.each do |command|
          command = ApplicationCommand.new(command, @bot)
          @application_commands[command.id] = command
        end

        @application_command_data = nil
      end
    end

    # A partial integration for an audit log entry.
    class Integration
      include Snowflake

      # @return [String] the name of the integration.
      attr_reader :name

      # @return [Symbol] the type of the integration.
      attr_reader :type

      # @return [Guild] the guild of the integration.
      attr_reader :guild

      # @return [String] the account ID of the integration.
      attr_reader :account_id

      # @return [String] the account name of the integration.
      attr_reader :account_name

      # @return [Integer, nil] the application ID of the integration.
      attr_reader :application_id

      # @!visibility private
      def initialize(data, guild, bot)
        @bot = bot
        @guild = guild
        @id = data[:id].to_i
        @name = data[:name]
        @type = data[:type]&.to_sym
        @account_id = data[:account]&.[](:id)
        @account_name = data[:account]&.[](:name)
        @application_id = data[:application_id]&.to_i
      end

      # @!visibility private
      def inspect
        "<Integration id=#{@id} guild_id=#{@guild.id} name=\"#{@name}\">"
      end
    end

    # An action in a guild's audit log.
    class Entry
      include Snowflake

      # Mapping of action types.
      ACTIONS = {
        guild_update: 1,
        channel_create: 10,
        channel_update: 11,
        channel_delete: 12,
        channel_overwrite_create: 13,
        channel_overwrite_update: 14,
        channel_overwrite_delete: 15,
        member_kick: 20,
        member_prune: 21,
        member_ban_add: 22,
        member_ban_remove: 23,
        member_update: 24,
        member_role_update: 25,
        member_move: 26,
        member_disconnect: 27,
        bot_add: 28,
        role_create: 30,
        role_update: 31,
        role_delete: 32,
        invite_create: 40,
        invite_update: 41,
        invite_delete: 42,
        webhook_create: 50,
        webhook_update: 51,
        webhook_delete: 52,
        emoji_create: 60,
        emoji_update: 61,
        emoji_delete: 62,
        message_delete: 72,
        bulk_delete_messages: 73,
        message_pin: 74,
        message_unpin: 75,
        integration_create: 80,
        integration_update: 81,
        integration_delete: 82,
        stage_instance_create: 83,
        stage_instance_update: 84,
        stage_instance_delete: 85,
        sticker_create: 90,
        sticker_update: 91,
        sticker_delete: 92,
        scheduled_event_create: 100,
        scheduled_event_update: 101,
        scheduled_event_delete: 102,
        thread_create: 110,
        thread_update: 111,
        thread_delete: 112,
        application_command_permission_update: 121,
        soundboard_sound_create: 130,
        soundboard_sound_update: 131,
        soundboard_sound_delete: 132,
        automod_rule_create: 140,
        automod_rule_update: 141,
        automod_rule_delete: 142,
        automod_block_message: 143,
        automod_flag_to_channel: 144,
        automod_timeout_user: 145,
        automod_quarantine_user: 146,
        creator_monetization_request_created: 150,
        creator_monetization_terms_accepted: 151,
        onboarding_prompt_create: 163,
        onboarding_prompt_update: 164,
        onboarding_prompt_delete: 165,
        onboarding_create: 166,
        onboarding_update: 167,
        home_feature_item: 171,
        home_remove_item: 172,
        harmful_links_blocked_message: 180,
        home_settings_create: 190,
        home_settings_update: 191,
        voice_channel_status_create: 192,
        voice_channel_status_delete: 193,
        scheduled_event_exception_create: 200,
        scheduled_event_exception_update: 201,
        scheduled_event_exception_delete: 202,
        member_verification_update: 210,
        profile_update: 211,
        pin_permission_migration_complete: 212,
        bypass_slowmode_permission_migration_complete: 213
      }.freeze

      # @return [Integer] the action type of the entry.
      attr_reader :action

      # @return [String, nil] the reason for performing the action.
      attr_reader :reason

      # @return [Array<Change>] the changes made to the target entity.
      attr_reader :changes

      # @return [Integer, nil] the user who performed the changes to the target.
      attr_reader :user_id

      # @return [Entities, nil] the entities that may be referenced by the entry.
      #   Only provided by {Guild#audit_logs}.
      attr_reader :entities

      # @return [Metadata] any additional info about the entry. Will only contain
      #   data for certain types of entries.
      attr_reader :metadata

      # @return [Integer, nil] the ID of the entity that was targeted, or `nil` if
      #   a single specific entity was not targeted.
      attr_reader :target_id

      # @!visibility private
      def initialize(data, entities, bot)
        @bot = bot
        @entities = entities
        @id = data[:id].to_i
        @action = data[:action_type]
        @guild_id = data[:guild_id]&.to_i
        @reason = data[:reason]
        @user_id = data[:user_id]&.to_i
        @metadata = Metadata.new(data[:options] || {}, @bot)
        @target_id = data[:target_id]&.to_i
        @changes = data[:changes]&.map { |item| Change.new(item, @bot) } || []
      end

      # Get the user who performed the changes.
      # @return [User] The user who performed the changes.
      def user
        @user ||= (@bot.user(@user_id) if @user_id)
      end

      # Get the guild that the current entry originates from.
      # @return [Guild] The guild that the entry originates from.
      def guild
        @entities&.guild || (@bot.guild(@guild_id) if @guild_id)
      end

      # @!visibility private
      def inspect
        "<Entry id=#{@id} action=#{@action} user_id=#{@user_id || 'nil'}>"
      end
    end

    # Represents a changed field for an entity.
    class Change
      # @return [Object] the new value of the field.
      attr_reader :new

      # @return [Object] the old value of the field.
      attr_reader :old

      # @return [String] the name of the changed field.
      attr_reader :field

      # @return [true, false] if the new value was set to `nil`.
      attr_reader :to_nil
      alias to_nil? to_nil

      # @return [true, false] if the old value was previously `nil`.
      attr_reader :from_nil
      alias from_nil? from_nil

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @new = data[:new_value]
        @old = data[:old_value]
        @to_nil = data.key?(:old_value) && !data.key?(:new_value)
        @from_nil = !data.key?(:old_value) && data.key?(:new_value)
        @field = data[:key].tap { |key| key&.gsub!(/^\$|_hash$/, '') }
      end
    end

    # Extra info for an audit log entry.
    class Metadata
      # @return [Hash] the raw unfiltered metadata.
      attr_reader :data

      # @return [Integer, nil] the amount of entities targeted.
      attr_reader :amount

      # @return [String, nil] the name of the overwritten role.
      attr_reader :role_name

      # @return [Integer, nil] the ID of the channel that was targeted.
      attr_reader :channel_id

      # @return [Integer, nil] the amount of days the prune operation targeted.
      attr_reader :prune_days

      # @return [Integer, nil] the ID of the message that was pinned or un-pinned.
      attr_reader :message_id

      # @return [Integer, nil] the ID of the permissions overwrite that was targeted.
      attr_reader :overwrite_id

      # @return [Symbol, nil] the type of the permissions overwrite that was targeted.
      attr_reader :overwrite_type

      # @return [Integer, nil] The ID of the application whose permissions were targeted.
      attr_reader :application_id

      # @return [Symbol, nil] the type of integration that kicked the member or changed roles.
      attr_reader :integration_type

      # @return [String, nil] the name of the auto-moderation rule that was triggered.
      attr_reader :automod_rule_name

      # @return [Integer, nil] the amount of members that were removed in the prune operation.
      attr_reader :pruned_member_count

      # @return [String, nil] the new status of the voice channel.
      attr_reader :voice_channel_status

      # @return [Integer, nil] the trigger type of the auto-moderation rule that was triggered.
      attr_reader :automod_rule_trigger_type

      # @return [Integer, nil] the ID of the guild scheduled event exception that was targeted.
      attr_reader :scheduled_event_exception_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @data = data
        @amount = data[:count]&.to_i
        @role_name = data[:role_name]
        @channel_id = data[:channel_id]&.to_i
        @prune_days = data[:delete_member_days]&.to_i
        @message_id = data[:message_id]&.to_i
        @overwrite_id = data[:id]&.to_i
        @overwrite_type = Overwrite::TYPES.key(data[:type].to_i) if data[:type]
        @application_id = data[:application_id]&.to_i
        @integration_type = data[:integration_type]&.to_sym
        @automod_rule_name = data[:auto_moderation_rule_name]
        @pruned_member_count = data[:members_removed]&.to_i
        @voice_channel_status = data[:status] == '' ? nil : data[:status]
        @automod_rule_trigger_type = data[:auto_moderation_rule_trigger_type]&.to_i
        @scheduled_event_exception_id = data[:exception_id]&.to_i
      end
    end
  end
end
