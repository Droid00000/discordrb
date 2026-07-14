# frozen_string_literal: true

module Discordrb
  # A command for an application.
  class ApplicationCommand
    include Snowflake

    # Mapping of types.
    TYPES = {
      chat_input: 1,
      user: 2,
      message: 3
    }.freeze

    # @return [Integer] the type of the application command.
    attr_reader :type

    # @return [String] the 1-32 character name of the application command.
    attr_reader :name

    # @return [Array<Option>] the top-level options for the application command.
    attr_reader :options

    # @return [Integer] how the application command's interactions should be handled.
    attr_reader :handler

    # @return [Integer] the version identifier of the application command.
    attr_reader :version

    # @return [Integer, nil] the ID of the guild the application command is for, if any.
    attr_reader :guild_id

    # @return [Array<Integer>] the contexts where the applicaction command can be used from.
    attr_reader :contexts

    # @return [String, nil] the 1-100 character description of the application command.
    attr_reader :description

    # @return [Integer] the ID of the application that the application command is associated with.
    attr_reader :application_id

    # @return [Array<SubcommandGroup>] the groups of subcommands for the application command.
    attr_reader :subcommand_groups

    # @return [Array<Integer>] the installation contexts where the application command is available.
    attr_reader :integration_types

    # @return [Hash<String => String>] a mapping of locale identifiers to localized application command names.
    attr_reader :name_localizations

    # @return [Permissions, nil] the permissions that are required for a member to run the command in a guild.
    attr_reader :default_permissions

    # @return [Hash<String => String>] a mapping of locale identifiers to localized application command descriptions.
    attr_reader :description_localizations

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @type = data[:type] || 1
      @handler = data[:handler] || 1
      @guild_id = data[:guild_id]&.to_i
      @application_id = data[:application_id]&.to_i
      update_data(data)
    end

    # Check if the command is age-restricted.
    # @return [true, false] Whether the application command is NSFW.
    def nsfw?
      @nsfw || false
    end

    # Get the guild that the application command is registered to.
    # @return [Guild, nil] The guild that the application command is for.
    def guild
      @bot.guild(@guild_id) if @guild_id
    end

    # Delete the application command. This cannot be undone without recreating the command.
    # @return [nil]
    def delete
      @bot.delete_application_command(command: @id, guild: @guild_id)
    end

    # Modify the properties of the application command.
    # @overload modify(name: :undef, nsfw: :undef, description: :undef, name_localizations: :undef, description_localizations: :undef, default_permissions: :undef, contexts: :undef, integration_types: :undef)
    #   @param name [String, Symbol] The 1-32 character name of the command.
    #   @param nsfw [true, false, nil] Whether the appplication command should be age-restricted.
    #   @param description [String, nil] The 1-100 character description of the chat-input command.
    #   @param name_localizations [Hash, #to_h, nil] A mapping of locales to localized command names.
    #   @param description_localizations [Hash, #to_h, nil] A mapping of locales to localized command descriptions.
    #   @param default_permissions [Permissions, Integer, String, nil] The default permissions required to invoke the command.
    #   @param contexts [Array<Symbol, Integer>, nil] The interaction contexts where the command can be invoked from.
    #   @param integration_types [Array<Symbol, Integer>, nil] The installation types where the command can be invoked from.
    #   @yieldparam builder [OptionBuilder] A builder for application command options, subcommands, and subcommand groups. Only for chat-input commands.
    # @return [nil]
    def modify(**, &)
      @bot.modify_application_command(**, command: @id, guild: @guild_id, &)
      nil
    end

    # Get a string that will mention the application command.
    # @param subcommand [String, nil] The subcommand to mention.
    # @param subcommand_group [String, nil] The subcommand group to mention.
    # @return [String] the layout to mention the command in a mention.
    def mention(subcommand_group: nil, subcommand: nil)
      if subcommand_group && subcommand
        "</#{name} #{subcommand_group} #{subcommand}:#{id}>"
      elsif subcommand_group
        "</#{name} #{subcommand_group}:#{id}>"
      elsif subcommand
        "</#{name} #{subcommand}:#{id}>"
      else
        "</#{name}:#{id}>"
      end
    end

    alias_method :to_s, :mention

    # Get the subcommands for the application command.
    # @param groups [true, false] Whether to include subcommands nested in groups.
    # @return [Array<Subcommand>] All of the subcommands for the application command.
    def subcommands(groups: true)
      groups ? (@subcommands + @subcommand_groups.flat_map(&:subcommands)) : @subcommands
    end

    # Get the permission configuration for the application command in a specific guild.
    # @param guild [Integer, String, Guild nil] The guild to fetch command permissions for.
    # @return [Array<Permission>] The permissions for the application command in the given guild.
    def permissions(guild: nil)
      raise ArgumentError, "A 'guild' must be provided for global application commands" unless @guild_id || guild

      response = @bot.http.get_application_command_permissions(@bot.profile.id, @guild_id || guild&.resolve_id, @id)
      response[:permissions].collect { |permission| Permission.new(permission, response, @bot) }
    rescue Discordrb::Errors::NotFound
      # If there aren't any explicit overwrites configured for the command, the response is a 404.
      []
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data[:name]
      @nsfw = new_data[:nsfw] || false
      @version = new_data[:version]
      @contexts = new_data[:contexts] || []
      @description = new_data[:description] == '' ? nil : new_data[:description]
      @integration_types = new_data[:integration_types] || []
      @name_localizations = new_data[:name_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
      @default_permissions = Permissions.new(new_data[:default_member_permissions]) if new_data[:default_member_permissions]
      @description_localizations = new_data[:description_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}

      @options = []
      @subcommands = []
      @subcommand_groups = []

      new_data[:options]&.each do |option|
        case option[:type]
        when Interactions::OptionBuilder::TYPES[:subcommand]
          @subcommands << Subcommand.new(option, self, @bot)
        when Interactions::OptionBuilder::TYPES[:subcommand_group]
          @subcommand_groups << SubcommandGroup.new(option, self, @bot)
        else
          @options << Option.new(option, self, @bot)
        end
      end
    end

    # A pre-filled choice that a user can pick.
    class Choice
      # @return [String] the name of the choice.
      attr_reader :name

      # @return [String, Integer, Float] the value of the choice.
      attr_reader :value

      # @return [Hash<String => String>] a mapping of local identifiers to localized choice names.
      attr_reader :name_localizations

      # @!visibility private
      def initialize(data, parent, bot)
        @bot = bot
        @parent = parent
        @name = data[:name]
        @value = data[:value]
        @name_localizations = data[:name_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
      end
    end

    # An option for an application command.
    class Option
      # @return [String] the name of the option.
      attr_reader :name

      # @return [Integer] the type of the option.
      attr_reader :type

      # @return [Array<Choice>] the choices that the user can pick from.
      attr_reader :choices

      # @return [Array<String>] the file-types to restrict attachment uploads to.
      attr_reader :file_types

      # @return [String] the description for the option, between 1-100 characters.
      attr_reader :description

      # @return [Array<Integer>] the types of channels to restrict the channel option to.
      attr_reader :channel_types

      # @return [Hash<String => String>] a mapping of locale identifiers to localized option names.
      attr_reader :name_localizations

      # @return [Hash<String => String>] a mapping of locale identifiers to localized option descriptions.
      attr_reader :description_localizations

      # @!visibility private
      def initialize(data, parent, bot)
        @bot = bot
        @parent = parent
        @name = data[:name]
        @type = data[:type]
        @choices = data[:choices]&.map { |item| Choice.new(item, self, @bot) } || []
        @required = data[:required]
        @min_value = data[:min_value]
        @max_value = data[:max_value]
        @min_length = data[:min_length]
        @max_length = data[:max_length]
        @file_types = data[:file_types] || []
        @description = data[:description]
        @autocomplete = data[:autocomplete]
        @channel_types = data[:channel_types] || []
        @name_localizations = data[:name_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
        @description_localizations = data[:description_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
      end

      # Get the minimum value for the option.
      # @return [Integer, Float, nil] The minimum float or integer
      #   that can be provided, or the minimum length of the string value, if any.
      def min
        @min_value || @min_length
      end

      # Get the maximum value for the option.
      # @return [Integer, Float, nil] The maximum float or integer
      #   that can be provided, or the maximum length of the string value, if any.
      def max
        @max_value || @max_length
      end

      # @!attribute [r] required?
      #   @return [true, false] whether the user must provide a value for the option.
      # @!attribute [r] autocomplete?
      #   @return [true, false] whether the option can dynamically return data when typed into.
      %i[required autocomplete].each do |name|
        define_method("#{name}?") { instance_variable_get("@#{name}") }
      end

      # @!method string?
      #   @return [true, false] whether the option will accept a string.
      # @!method integer?
      #   @return [true, false] whether the option will accept a whole integer.
      # @!method boolean?
      #   @return [true, false] whether the option will either accept `true` or `false`.
      # @!method user?
      #   @return [true, false] whether the option will accept a user or member.
      # @!method channel?
      #   @return [true, false] whether the option will accept a channel.
      # @!method role?
      #   @return [true, false] whether the option will accept a role (excluding the default role).
      # @!method mentionable?
      #   @return [true, false] whether the option will accept either a role or a user.
      # @!method number?
      #   @return [true, false] whether the option will accept a decimal value.
      # @!method attachment?
      #   @return [true, false] whether the option will accept an attachment/file.
      Interactions::OptionBuilder::TYPES.each do |name, value|
        define_method("#{name}?") { @type == value } if name != :subcommand || name != :subcommand_group
      end
    end

    # A group of subcommands.
    class SubcommandGroup
      include Enumerable

      # @return [String] the name of the group.
      attr_reader :name

      # @return [Array<Option>] the group's subcommands.
      attr_reader :subcommands

      # @return [String] the description of the subcommad group.
      attr_reader :description

      # @return [Hash<String => String>] a mapping of locale identifiers to localized group names.
      attr_reader :name_localizations

      # @return [Hash<String => String>] a mapping of locale identifiers to localized group descriptions.
      attr_reader :description_localizations

      # @!visibility private
      def initialize(data, parent, bot)
        @bot = bot
        @parent = parent
        @name = data[:name]
        @subcommands = data[:options]&.map { |item| Subcommand.new(item, self, @bot) } || []
        @description = data[:description]
        @name_localizations = data[:name_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
        @description_localizations = data[:description_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
      end

      # @!visibility private
      def each(...)
        @subcommands.each(...)
      end
    end

    # A single subcommand.
    class Subcommand
      # @return [String] the name of the subcommand.
      attr_reader :name

      # @return [Array<Option>] the subcommand's options.
      attr_reader :options

      # @return [String] the description of the subcommand.
      attr_reader :description

      # @return [Hash<String => String>] a mapping of locale identifiers to localized subcommand names.
      attr_reader :name_localizations

      # @return [Hash<String => String>] a mapping of locale identifiers to localized subcommand descriptions.
      attr_reader :description_localizations

      # @!visibility private
      def initialize(data, parent, bot)
        @bot = bot
        @parent = parent
        @name = data[:name]
        @options = data[:options]&.map { |item| Option.new(item, self, @bot) }
        @description = data[:description]
        @name_localizations = data[:name_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
        @description_localizations = data[:description_localizations]&.tap { |hash| hash.transform_keys!(&:to_s) } || {}
      end
    end

    # An application command permission for a channel, member, or a role.
    class Permission
      # Map of permission types.
      TYPES = {
        role: 1,
        member: 2,
        channel: 3
      }.freeze

      # @return [Integer] the type of the permission.
      # @see TYPES
      attr_reader :type

      # @return [Integer] the ID of the guild the permission is for.
      attr_reader :guild_id

      # @return [Integer] the ID of the entity the permission is for.
      attr_reader :target_id

      # @!visibility private
      def initialize(data, command, bot)
        @bot = bot
        @type = data[:type]
        @target_id = data[:id].to_i
        @overwrite = data[:permission]
        @command_id = command[:id].to_i
        @guild_id = command[:guild_id].to_i
        @application_id = command[:application_id].to_i
      end

      # Whether this permission has been allowed, e.g has a green check in the UI.
      # @return [true, false]
      def allowed?
        @overwrite == true
      end

      # Whether this permission has been denied, e.g has a red X-mark in the UI.
      # @return [true, false]
      def denied?
        @overwrite == false
      end

      # Whether this permission is applied to the everyone role in the guild.
      # @return [true, false]
      def everyone?
        @target_id == @guild_id
      end

      # Get the ID of the application command this permission is for.
      # @return [Integer, nil] This will be `nil` if the permission is the
      #   default permission.
      def command_id
        @command_id unless default?
      end

      # Whether this permission is the default for all commands that don't
      #  contain explicit permission oerwrites.
      # @return [true, false]
      def default?
        @command_id == @application_id
      end

      # Whether this permission is applied to every channel in the guild.
      # @return [true, false]
      def all_channels?
        @target_id == (@guild_id - 1)
      end

      # Get the user, role, or channel(s) that this permission targets.
      # @return [Array<Channel>, Role, Member]
      def target
        case @type
        when TYPES[:role]
          @bot.guild(@guild_id).role(@target_id)
        when TYPES[:member]
          @bot.guild(@guild_id).member(@target_id)
        when TYPES[:channel]
          all_channels? ? @bot.guild(@guild_id).channels : [@bot.channel(@target_id)]
        end
      end

      alias_method :targets, :target

      # @!method role?
      #   @return [true, false] whether this permission is for a role.
      # @!method member?
      #   @return [true, false] whether this permission is for a member.
      # @!method channel?
      #   @return [true, false] whether this permission is for a channel.
      TYPES.each do |name, value|
        define_method("#{name}?") do
          @type == value
        end
      end
    end
  end
end
