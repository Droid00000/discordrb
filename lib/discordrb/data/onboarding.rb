# frozen_string_literal: true

module Discordrb
  # The onboarding flow for new members in a server.
  class Onboarding
    # Map of onboarding mode types.
    MODES = {
      default: 0,
      advanced: 1
    }.freeze

    # @return [Server] The server this onboarding object is for.
    attr_reader :server

    # @return [Integer] The current onboarding mode.
    attr_reader :mode

    # @return [true, false] Whether onboarding is enabled or not.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [Array<Prompt>] Prompts shown during onboarding.
    attr_reader :prompts

    # @return [Array<Channel>] Default channels that members automatically get opted into.
    attr_reader :default_channels

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      from_other(data)
    end

    # @return [true, false] Whether the onboarding mode only counts default channels towards constraints.
    def default?
      @mode == MODES[:default]
    end

    # @return [true, false] Whether the onboarding mode counts default channels and questions towards constraints.
    def advanced?
      @mode == MODES[:advanced]
    end

    # Get a prompt by its ID.
    # @param id [Integer, String] The ID of the prompt to find.
    # @return [Prompt, nil] the prompt or nil if it couldn't be found.
    def prompt(id)
      prompts.find { |prompt| prompt.id == id.resolve_id }
    end

    # Set the default channels for this onboarding flow.
    # @param channels [Array<Channel, Integer, String>] The new default channels.
    def default_channels=(channels)
      update_data(default_channels: channels.map(&:resolve_id))
    end

    # Set whether onboarding is enabled or not.
    # @param enabled [true, false] Whether onboarding is enabled or not.
    def enabled=(enabled)
      update_data(enabled: enabled)
    end

    # Set the mode for this onboarding flow.
    # @param mode [Symbol, Integer] The new onboarding mode.
    def mode=(mode)
      update_data(mode: MODES[mode] || mode)
    end

    # Remove a prompt from this onboarding flow.
    def remove_prompt(id)
      prompts.delete(prompt(id))

      update_data(prompts: prompts.map(&:to_h))
    end

    # Add a prompt to this onboarding flow.
    # @yieldparam [PromptBuilder]
    def add_prompt
      yield (builder = PromptBuilder.new)

      update_data(prompts: prompts.map(&:to_h) + builder.to_a)
    end

    # @!visibility private
    def from_other(new_data)
      @mode = new_data['mode']
      @enabled = new_data['enabled']
      @prompts = new_data['prompts'].map { |prompt| Prompt.new(prompt, server, bot) }
      @default_channels = new_data['default_channel_ids'].map { |id| @bot.channel(id) }
    end

    # @!visibility private
    def update_data(new_data)
      from_other(JSON.parse(API::Server.modify_onboarding(@bot.token, server.id,
                                                          new_data[:mode] || :undef,
                                                          new_data[:prompts]&.to_a || :undef,
                                                          new_data[:default_channels] || :undef,
                                                          new_data.key?(:enabled) ? new_data[:enabled] : :undef)))
    end

    # A prompt that can be shown during the inital onboarding flow.
    class Prompt
      include IDObject

      # Map of prompt types.
      TYPES = {
        multiple_choice: 0,
        dropdown: 1
      }.freeze

      # @return [Integer] The type of this prompt.
      attr_reader :type

      # @return [Array<Option>] Options inside of this prompt.
      attr_reader :options

      # @return [String] The title/question of this prompt.
      attr_reader :title

      # @return [true, false] Whether users are limited to selecting one option for the prompt
      attr_reader :single_select
      alias_method :single_select?, :single_select

      # @return [true, false] Whether this prompt is required before a user completes the onboarding flow.
      attr_reader :required
      alias_method :required?, :required

      # @return [true, false] whether the prompt is present in the onboarding flow. If false, the prompt
      #   will only appear in the Channels & Roles tab.
      attr_reader :in_onboarding
      alias_method :in_onboarding?, :in_onboarding

      # @!visibility private
      def initialize(data, server, bot)
        @bot = bot
        @id = data['id'].to_i
        @type = data['type']
        @options = data['options'].map { |opt| Option.new(opt, server, bot) }
        @title = data['title']
        @single_select = data['single_select']
        @required = data['required']
        @in_onboarding = data['in_onboarding']
      end

      # Get an option by its ID.
      # @param id [Integer, String] The ID of the option to find.
      # @return [Option, nil] the option or nil if it couldn't be found.
      def option(id)
        options.find { |option| option.id == id.resolve_id }
      end

      # @return [true, false] Whether this prompt has multiple choices.
      def multiple_choice?
        @type == TYPES[:multiple_choice]
      end

      # @return [true, false] Whether this prompt is a dropdown.
      def dropdown?
        @type == TYPES[:dropdown]
      end

      # @!visibility private
      def to_h
        {
          id: @id,
          type: @type,
          options: @options.map(&:to_h),
          title: @title,
          single_select: @single_select,
          required: @required,
          in_onboarding: @in_onboarding
        }
      end
    end

    # An option within an onboarding prompt.
    class Option
      include IDObject

      # @return [Emoji, nil] The emoji of this option.
      attr_reader :emoji

      # @return [String] The title of this option.
      attr_reader :title

      # @return [String, nil] The description of this option.
      attr_reader :description

      # @return [Array<Role>] Roles assigned to a member when the option is selected.
      attr_reader :roles

      # @return [Array<Channel>] Channels a member is added to when the option is selected.
      attr_reader :channels

      # @!visibility private
      def initialize(data, server, bot)
        @bot = bot
        @server = server
        @id = data['id'].to_i
        @emoji = Discordrb::Emoji.new(data['emoji'], bot) if data['emoji']
        @title = data['title']
        @description = data['description']
        @roles = data['role_ids'].map { |id| @server.role(id) }
        @channels = data['channel_ids'].map { |id| @bot.channel(id) }
      end

      # @!visibility private
      def to_h
        {
          id: @id,
          title: @title,
          description: @description,
          channel_ids: @channels.map(&:resolve_id),
          role_ids: @roles.map(&:resolve_id),
          emoji_id: @emoji&.id,
          emoji_name: @emoji&.name,
          emoji_animated: @emoji&.animated?
        }.compact
      end
    end

    # Builder for onboarding prompts.
    class PromptBuilder
      # Map of prompt types.
      TYPES = {
        multiple_choice: 0,
        dropdown: 1
      }.freeze

      # @return [Array<Hash>]
      attr_reader :prompts
      alias_method :to_a, :prompts

      # @!visibility private
      def initialize
        @prompts = []
      end

      # @param title [String] The title of the prompt.
      # @param type [Symbol, Integer] The type of prompt. See {TYPES}.
      # @param single_select [Boolean] whether users are limited to selecting one option for the prompt.
      # @param required [Boolean] whether this prompt is required before a user completes the onboarding flow.
      # @param in_onboarding [Boolean] whether the prompt is present in the onboarding flow. If false, the prompt
      #   will only appear in the Channels & Roles tab.
      # @yieldparam [OptionBuilder]
      def prompt(title:, type:, single_select:, required:, in_onboarding:)
        builder = OptionBuilder.new
        yield builder if block_given?

        @prompts << { title: title, type: TYPES[type] || type, single_select: single_select,
                      required: required, in_onboarding: in_onboarding, options: builder.to_a }
      end

      # Builder for onboarding options.
      class OptionBuilder
        # @return [Array<Hash>]
        attr_reader :options
        alias_method :to_a, :options

        # @!visibility private
        def initialize
          @options = []
        end

        # @param title [String] The title of the option.
        # @param description [String, nil] The description of the option.
        # @param channels [Array<Channel, Integer>] Channels a member is added to when the option is selected.
        # @param roles [Array<Role, Integer>] Roles assigned to a member when the option is selected.
        # @param emoji [Emoji, String, nil] The emoji object, string for a unicode emoji, or nil for no emoji.
        def option(title:, description: nil, channels: [], roles: [], emoji: nil)
          emoji = case emoji
                  when String
                    { emoji_id: nil, emoji_name: emoji, emoji_animated: false }
                  when Emoji
                    { emoji_id: emoji.id, emoji_name: emoji.name, emoji_animated: emoji.animated? }
                  end

          @options << { title: title, description: description, role_ids: roles.map(&:resolve_id),
                        channel_ids: channels.map(&:resolve_id), **emoji }
        end
      end
    end
  end
end
