# frozen_string_literal: true

require 'discordrb/webhooks'

module Discordrb
  # Base class for interaction objects.
  class Interaction
    include Snowflake

    # Interaction types.
    # @see https://discord.com/developers/docs/interactions/slash-commands#interaction-interactiontype
    TYPES = {
      ping: 1,
      command: 2,
      component: 3,
      autocomplete: 4,
      modal_submit: 5
    }.freeze

    # Interaction response types.
    # @see https://discord.com/developers/docs/interactions/slash-commands#interaction-response-interactioncallbacktype
    CALLBACK_TYPES = {
      pong: 1,
      channel_message: 4,
      deferred_message: 5,
      deferred_update: 6,
      update_message: 7,
      autocomplete: 8,
      modal: 9
    }.freeze

    # Interaction context types.
    # @see https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-context-types
    CONTEXTS = {
      guild: 0,
      bot_dm: 1,
      private_channel: 2
    }.freeze

    # Application integration types.
    # @see https://discord.com/developers/docs/resources/application#application-object-application-integration-types
    INTEGRATION_TYPES = {
      guild: 0,
      user: 1
    }.freeze

    # @return [User, Member] The user that initiated the interaction.
    attr_reader :user

    # @return [Integer, nil] The ID of the guild this interaction originates from.
    attr_reader :guild_id

    # @return [Integer] The ID of the channel this interaction originates from.
    attr_reader :channel_id

    # @return [Channel] The channel where this interaction originates from.
    attr_reader :channel

    # @return [Integer] The ID of the application associated with this interaction.
    attr_reader :application_id

    # @return [String] The interaction token.
    attr_reader :token

    # @!visibility private
    # @return [Integer] Currently pointless
    attr_reader :version

    # @return [Integer] The type of this interaction.
    # @see TYPES
    attr_reader :type

    # @return [Hash] The interaction data.
    attr_reader :data

    # @return [Interactions::Message, nil] The message associated with this interaction.
    attr_reader :message

    # @return [Array<ActionRow>] The modal components associated with this interaction.
    attr_reader :components

    # @return [Permissions] The permissions the application has where this interaction originates from.
    attr_reader :application_permissions

    # @return [String] The selected language of the user that initiated this interaction.
    attr_reader :user_locale

    # @return [String, nil] The selected language of the guild this interaction originates from.
    attr_reader :guild_locale

    # @return [Integer] The context of where this interaction was initiated from.
    attr_reader :context

    # @return [Integer] The maximum number of bytes an attachment can have when responding to this interaction.
    attr_reader :max_attachment_size

    # @return [Array<Symbol>] The features of the guild where this interaction was initiated from.
    attr_reader :guild_features

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @application_id = data[:application_id].to_i
      @type = data[:type]
      @message = Interactions::Message.new(data[:message], @bot, self) if data[:message]
      @data = data[:data]
      @guild_id = data[:guild_id]&.to_i
      @channel_id = data[:channel_id]&.to_i
      @channel = @bot.ensure_channel(data[:channel], nil, true) if data[:channel]
      @user = if data[:member]
                data[:member][:guild_id] = @guild_id
                data[:member][:_interaction_channel_id] = @channel_id
                Discordrb::Member.new(data[:member], bot.guilds[@guild_id], @bot)
              else
                @bot.ensure_user(data[:user], true)
              end
      @token = data[:token]
      @version = data[:version]
      @components = @data[:components]&.filter_map { |component| Components.from_data(component, @bot) } || []
      @application_permissions = Permissions.new(data[:app_permissions]) if data[:app_permissions]
      @user_locale = data[:locale]
      @guild_locale = data[:guild_locale]
      @context = data[:context]
      @max_attachment_size = data[:attachment_size_limit]
      @guild_features = data[:guild] ? data[:guild][:features]&.map(&:to_sym) : []
      @integration_owners = data[:authorizing_integration_owners]&.transform_values(&:to_i)
    end

    # Respond to the creation of this interaction. An interaction must be responded to or deferred,
    # The response may be modified with {Interaction#edit_response} or deleted with {Interaction#delete_response}.
    # Further messages can be sent with {Interaction#send_message}.
    # @param content [String] The content of the message.
    # @param tts [true, false]
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @param flags [Integer] Message flags.
    # @param ephemeral [true, false] Whether this message should only be visible to the interaction initiator.
    # @param components [Array<#to_h>] An array of components.
    # @param attachments [Array<File>] Files that can be referenced in embeds and components via `attachment://file.png`.
    # @param has_components [true, false] Whether this message includes any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to this message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    # @yieldparam view [Webhooks::View] A builder for creating interaction components.
    # @return [Interactions::Message] The message that was created.
    def respond(content: nil, tts: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: nil, components: nil, attachments: nil, has_components: false, poll: nil)
      flags |= (1 << 6) if ephemeral
      flags |= (1 << 15) if has_components

      builder = Discordrb::Webhooks::Builder.new
      view = Discordrb::Webhooks::View.new

      prepare_builder(builder, content, embeds, allowed_mentions, poll)
      yield(builder, view) if block_given?
      data = builder.to_json_hash

      callback = {
        with_response: true,
        files: attachments&.map { |file| file.is_a?(Hash) ? file : { file: file } },
        type: CALLBACK_TYPES[:channel_message],
        data: {
          tts: tts,
          content: data[:content],
          embeds: data[:embeds],
          allowed_mentions: data[:allowed_mentions],
          flags: flags,
          components: components&.to_a || view&.to_a,
          poll: data[:poll],
          attachments: attachments&.any? ? [] : nil
        }.compact
      }

      response = @bot.http.create_interaction_response(@id, @token, **callback)
      Interactions::Message.new(response[:resource][:message], @bot, self)
    end

    # Defer an interaction, setting a temporary response that can be later overriden by {Interaction#send_message}.
    # This method is used when you want to use a single message for your response but require additional processing time, or to simply ack
    # an interaction so an error is not displayed.
    # @param flags [Integer] Message flags.
    # @param ephemeral [true, false] Whether this message should only be visible to the interaction initiator.
    # @return [nil]
    def defer(flags: 0, ephemeral: true)
      flags |= (1 << 6) if ephemeral

      @bot.http.create_interaction_response(@id, @token, type: CALLBACK_TYPES[:deferred_message], data: { flags: flags })
      nil
    end

    # Defer an update to an interaction. This is can only currently used by Button interactions.
    def defer_update
      @bot.http.create_interaction_response(@id, @token, type: CALLBACK_TYPES[:deferred_update])
    end

    # Create a modal as a response.
    # @param title [String] The title of the modal being shown.
    # @param custom_id [String] The custom_id used to identify the modal and store data.
    # @param components [Array<Component, Hash>, nil] An array of components. These can be defined through the block as well.
    # @yieldparam [Discordrb::Webhooks::Modal] A builder for the modal's components.
    # @return [nil]
    def show_modal(title:, custom_id:, components: nil)
      return if @type == Interaction::TYPES[:modal_submit]

      if block_given?
        modal_builder = Discordrb::Webhooks::Modal.new
        yield modal_builder

        components = modal_builder.to_a
      end

      callback = {
        type: CALLBACK_TYPES[:modal],
        data: {
          title: title,
          custom_id: custom_id,
          components: components.to_a
        }
      }

      @bot.http.create_interaction_response(@id, @token, **callback)
      nil
    end

    # Respond to the creation of this interaction. An interaction must be responded to or deferred,
    # The response may be modified with {Interaction#edit_response} or deleted with {Interaction#delete_response}.
    # Further messages can be sent with {Interaction#send_message}.
    # @param content [String] The content of the message.
    # @param tts [true, false]
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @param flags [Integer] Message flags.
    # @param ephemeral [true, false] Whether this message should only be visible to the interaction initiator.
    # @param components [Array<#to_h>] An array of components.
    # @param attachments [Array<File>] Files that can be referenced in embeds and components via `attachment://file.png`.
    # @param has_components [true, false] Whether this message includes any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to this message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    # @yieldparam view [Webhooks::View] A builder for creating interaction components.
    # @return [Interactions::Message] The message that was updated.
    def update_message(content: nil, tts: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: nil, components: nil, attachments: nil, has_components: false, poll: nil)
      flags |= (1 << 6) if ephemeral
      flags |= (1 << 15) if has_components

      builder = Discordrb::Webhooks::Builder.new
      view = Discordrb::Webhooks::View.new

      prepare_builder(builder, content, embeds, allowed_mentions, poll)
      yield(builder, view) if block_given?
      data = builder.to_json_hash

      callback = {
        with_response: true,
        files: attachments&.map { |file| file.is_a?(Hash) ? file : { file: file } },
        type: CALLBACK_TYPES[:update_message],
        data: {
          tts: tts,
          content: data[:content],
          embeds: data[:embeds],
          allowed_mentions: data[:allowed_mentions],
          flags: flags,
          components: components&.to_a || view&.to_a,
          poll: data[:poll],
          attachments: attachments&.any? ? [] : nil
        }.compact
      }

      response = @bot.http.create_interaction_response(@id, @token, **callback)
      Interactions::Message.new(response[:resource][:message], @bot, self)
    end

    # Edit the original response to this interaction.
    # @param content [String] The content of the message.
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @param flags [Integer] Message flags.
    # @param components [Array<#to_h>] An array of components.
    # @param attachments [Array<File>] Files that can be referenced in embeds and components via `attachment://file.png`.
    # @param has_components [true, false] Whether this message includes any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to this message.
    # @return [InteractionMessage] The updated response message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    # @yieldparam view [Webhooks::View] A builder for creating interaction components.
    # @return [Interactions::Message] The message that was updated.
    def edit_response(content: nil, embeds: nil, allowed_mentions: nil, flags: 0, components: nil, attachments: nil, has_components: false, poll: nil)
      flags |= (1 << 15) if has_components
      builder = Discordrb::Webhooks::Builder.new
      view = Discordrb::Webhooks::View.new

      prepare_builder(builder, content, embeds, allowed_mentions, poll)
      yield(builder, view) if block_given?
      data = builder.to_json_hash

      callback = {
        content: data[:content],
        embeds: data[:embeds],
        allowed_mentions: data[:allowed_mentions],
        flags: flags,
        components: components&.to_a || view&.to_a,
        poll: data[:poll],
        files: attachments&.map { |file| file.is_a?(Hash) ? file : { file: file } }
      }.compact

      response = @bot.http.edit_original_interaction_response(@application_id, @token, **callback)
      Interactions::Message.new(response, @bot, self)
    end

    # Delete the original interaction response.
    def delete_response
      @bot.http.delete_original_interaction_response(@application_id, @token)
      nil
    end

    # @param content [String] The content of the message.
    # @param tts [true, false]
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @param flags [Integer] Message flags.
    # @param ephemeral [true, false] Whether this message should only be visible to the interaction initiator.
    # @param attachments [Array<File>] Files that can be referenced in embeds and components via `attachment://file.png`.
    # @param has_components [true, false] Whether this message includes any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to this message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    # @yieldparam view [Webhooks::View] A builder for creating interaction components.
    # @return [Interactions::Message] The message that was created.
    def send_message(content: nil, embeds: nil, tts: false, allowed_mentions: nil, flags: 0, ephemeral: false, components: nil, attachments: nil, has_components: false, poll: nil)
      flags |= (1 << 6) if ephemeral
      flags |= (1 << 15) if has_components

      builder = Discordrb::Webhooks::Builder.new
      view = Discordrb::Webhooks::View.new

      prepare_builder(builder, content, embeds, allowed_mentions, poll)
      yield(builder, view) if block_given?
      data = builder.to_json_hash

      callback = {
        wait: true,
        content: data[:content],
        embeds: data[:embeds],
        tts: tts,
        allowed_mentions: data[:allowed_mentions],
        flags: flags,
        components: components&.to_a || view&.to_a,
        files: attachments&.map { |file| file.is_a?(Hash) ? file : { file: file } },
        poll: data[:poll]
      }.compact

      response = @bot.http.create_followup_message(@application_id, @token, **callback)
      Interactions::Message.new(response, @bot, self)
    end

    # @param message [String, Integer, InteractionMessage, Message] The message created by this interaction to be edited.
    # @param content [String] The message content.
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @param attachments [Array<File>] Files that can be referenced in embeds via `attachment://file.png`.
    # @param flags [Integer] Message flags.
    # @param has_components [true, false] Whether this message includes any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to this message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    # @yieldparam view [Webhooks::View] A builder for creating interaction components.
    # @return [Interactions::Message] The message that was edited.
    def edit_message(message, content: nil, embeds: nil, allowed_mentions: nil, components: nil, attachments: nil, flags: 0, has_components: false, poll: nil)
      flags |= (1 << 15) if has_components

      builder = Discordrb::Webhooks::Builder.new
      view = Discordrb::Webhooks::View.new

      prepare_builder(builder, content, embeds, allowed_mentions, poll)
      yield(builder, view) if block_given?
      data = builder.to_json_hash

      callback = {
        content: data[:content],
        embeds: data[:embeds],
        allowed_mentions: data[:allowed_mentions],
        components: components&.to_a || view&.to_a,
        files: attachments&.map { |file| file.is_a?(Hash) ? file : { file: file } },
        flags: flags,
        poll: data[:poll]
      }.compact

      response = @bot.http.edit_followup_message(@application_id, @token, message.resolve_id, **callback)
      Interactions::Message.new(response, @bot, self)
    end

    # @param message [Integer, String, InteractionMessage, Message] The message created by this interaction to be deleted.
    def delete_message(message)
      @bot.http.delete_webhook_message(@application_id, @token, message.resolve_id)
      nil
    end

    # Show autocomplete choices as a response.
    # @param choices [Array<Hash>, Hash] Array of autocomplete choices to show the user.
    # @return [nil]
    def show_autocomplete_choices(choices)
      callback = {
        type: CALLBACK_TYPES[:autocomplete],
        data: {
          choices: choices.is_a?(Array) ? choices : choices.map { |name, value| { name:, value: } }
        }
      }

      @bot.http.create_interaction_response(@id, @token, **callback)
      nil
    end

    # Get the guild associated with the interaction.
    # @return [Guild, nil] This will be nil for interactions that occur in DM channels or guilds where the bot
    #   does not have the `bot` scope.
    def guild
      defined?(@guild) ? @guild : (@guild = @bot.guild(@guild_id))
    end

    # Get the button component that triggered the interaction.
    # @return [Components::Button, nil] The button that triggered this interaction if applicable, otherwise `nil`.
    def button
      @type == TYPES[:component] ? get_component(@data[:custom_id]) : nil
    end

    # Get the text input components associated with the interaction.
    # @return [Array<TextInput>] The text input components associated with this interaction.
    def text_inputs
      @components.filter_map do |entity|
        entity.component if entity.is_a?(Components::Label) && entity.component.is_a?(Components::TextInput)
      end
    end

    # Get a component by its custom ID.
    # @param custom_id [String] the custom ID of the component to find.
    # @return [TextInput, Button, SelectMenu, Checkbox, ModalActionGroup, nil] The component associated with the custom ID, or `nil`.
    def get_component(custom_id)
      components = flatten_components((@message&.components || []) + @components)
      components.find { |component| component.respond_to?(:custom_id) && component.custom_id == custom_id }
    end

    # @return [true, false] whether the application was installed by the user who initiated this interaction.
    def user_integration?
      @integration_owners[:'1'] == @user.id
    end

    # @return [true, false] whether the application was installed by the guild where this interaction originates from.
    def guild_integration?
      @guild_id ? @integration_owners[:'0'] == @guild_id : false
    end

    private

    # Set builder defaults from parameters
    # @param builder [Discordrb::Webhooks::Builder]
    # @param content [String, nil]
    # @param embeds [Array<Hash, Discordrb::Webhooks::Embed>, nil]
    # @param allowed_mentions [AllowedMentions, Hash, nil]
    # @param poll [Poll, Poll::Builder, Hash, nil]
    def prepare_builder(builder, content, embeds, allowed_mentions, poll)
      builder.poll = poll
      builder.content = content
      builder.allowed_mentions = allowed_mentions
      embeds&.each { |embed| builder << embed }
    end

    # @!visibility private
    def flatten_components(components)
      components = components.flat_map do |entity|
        case entity
        when Components::ActionRow
          entity.components
        when Components::Label
          entity.component
        when Components::Section
          entity.accessory if entity.accessory.respond_to?(:custom_id)
        when Components::Container
          flatten_components(entity.components)
        else
          entity if entity.respond_to?(:custom_id)
        end
      end

      components.compact
    end
  end

  # Objects specific to Interactions.
  module Interactions
    # A builder for defining slash commands options.
    class OptionBuilder
      # @!visibility private
      TYPES = {
        subcommand: 1,
        subcommand_group: 2,
        string: 3,
        integer: 4,
        boolean: 5,
        user: 6,
        channel: 7,
        role: 8,
        mentionable: 9,
        number: 10,
        attachment: 11
      }.freeze

      # @return [Array<Hash>]
      attr_reader :options

      # @!visibility private
      def initialize
        @options = []
      end

      # @param name [String, Symbol] The name of the subcommand.
      # @param description [String] A description of the subcommand.
      # @yieldparam [OptionBuilder]
      # @return (see #option)
      # @example
      #   bot.register_application_command(:test, 'Test command') do |cmd|
      #     cmd.subcommand(:echo) do |sub|
      #       sub.string('message', 'What to echo back', required: true)
      #     end
      #   end
      def subcommand(name, description)
        builder = OptionBuilder.new
        yield builder if block_given?

        option(TYPES[:subcommand], name, description, options: builder.to_a)
      end

      # @param name [String, Symbol] The name of the subcommand group.
      # @param description [String] A description of the subcommand group.
      # @yieldparam [OptionBuilder]
      # @return (see #option)
      # @example
      #   bot.register_application_command(:test, 'Test command') do |cmd|
      #     cmd.subcommand_group(:fun) do |group|
      #       group.subcommand(:8ball) do |sub|
      #         sub.string(:question, 'What do you ask the mighty 8ball?')
      #       end
      #     end
      #   end
      def subcommand_group(name, description)
        builder = OptionBuilder.new
        yield builder

        option(TYPES[:subcommand_group], name, description, options: builder.to_a)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @param min_length [Integer] A minimum length for option value.
      # @param max_length [Integer] A maximum length for option value.
      # @param choices [Hash, nil] Available choices, mapped as `Name => Value`.
      # @param autocomplete [true, false] Whether this option can dynamically show choices.
      # @return (see #option)
      def string(name, description, required: nil, min_length: nil, max_length: nil, choices: nil, autocomplete: nil)
        option(TYPES[:string], name, description,
               required: required, min_length: min_length, max_length: max_length, choices: choices, autocomplete: autocomplete)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @param min_value [Integer] A minimum value for option.
      # @param max_value [Integer] A maximum value for option.
      # @param choices [Hash, nil] Available choices, mapped as `Name => Value`.
      # @param autocomplete [true, false] Whether this option can dynamically show choices.
      # @return (see #option)
      def integer(name, description, required: nil, min_value: nil, max_value: nil, choices: nil, autocomplete: nil)
        option(TYPES[:integer], name, description,
               required: required, min_value: min_value, max_value: max_value, choices: choices, autocomplete: autocomplete)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @return (see #option)
      def boolean(name, description, required: nil)
        option(TYPES[:boolean], name, description, required: required)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @return (see #option)
      def user(name, description, required: nil)
        option(TYPES[:user], name, description, required: required)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @param types [Array<Symbol, Integer>] See {Channel::TYPES}
      # @return (see #option)
      def channel(name, description, required: nil, types: nil)
        types = types&.collect { |type| type.is_a?(Numeric) ? type : Channel::TYPES[type] }
        option(TYPES[:channel], name, description, required: required, channel_types: types)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @return (see #option)
      def role(name, description, required: nil)
        option(TYPES[:role], name, description, required: required)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @return (see #option)
      def mentionable(name, description, required: nil)
        option(TYPES[:mentionable], name, description, required: required)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @param min_value [Float] A minimum value for option.
      # @param max_value [Float] A maximum value for option.
      # @param autocomplete [true, false] Whether this option can dynamically show choices.
      # @return (see #option)
      def number(name, description, required: nil, min_value: nil, max_value: nil, choices: nil, autocomplete: nil)
        option(TYPES[:number], name, description,
               required: required, min_value: min_value, max_value: max_value, choices: choices, autocomplete: autocomplete)
      end

      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @param types [Array<String, Symbol>] The file extensions or file groups to
      #   restrict the option to. This restriction is **only** a client-side check.
      # @return (see #option)
      def attachment(name, description, required: nil, types: nil)
        option(TYPES[:attachment], name, description, required: required, file_types: types)
      end

      # @!visibility private
      # @param type [Integer] The argument type.
      # @param name [String, Symbol] The name of the argument.
      # @param description [String] A description of the argument.
      # @param required [true, false] Whether this option must be provided.
      # @param min_value [Integer, Float] A minimum value for integer and number options.
      # @param max_value [Integer, Float] A maximum value for integer and number options.
      # @param min_length [Integer] A minimum length for string option value.
      # @param max_length [Integer] A maximum length for string option value.
      # @param channel_types [Array<Integer>] Channel types that can be provides for channel options.
      # @param autocomplete [true, false] Whether this option can dynamically show options.
      # @param file_types [Array<String, Symbol>] The file types to restrict this option to in the client.
      # @return [Hash]
      def option(type, name, description, required: nil, choices: nil, options: nil, min_value: nil, max_value: nil,
                 min_length: nil, max_length: nil, channel_types: nil, autocomplete: nil, file_types: nil)
        opt = { type: type, name: name, description: description }
        choices = choices.map { |option_name, value| { name: option_name, value: value } } if choices

        opt.merge!({ required: required, choices: choices, options: options, min_value: min_value,
                     max_value: max_value, min_length: min_length, max_length: max_length,
                     channel_types: channel_types, autocomplete: autocomplete, file_types: file_types }.compact)

        @options << opt
        opt
      end

      # @return [Array<Hash>]
      def to_a
        @options
      end
    end

    # A message partial for interactions.
    class Message < Discordrb::Message
      # @!visibility private
      def initialize(data, bot, interaction)
        super(data, bot)

        @interaction = interaction
      end

      # Respond to the message.
      # @see Interaction#send_message
      # @return [Message]
      def respond(...)
        @interaction.send_message(...)
      end

      # Delete the message.
      # @return [nil]
      def delete
        @interaction.delete_message(@id)
      end

      # Edit the message's data.
      # @see Interaction#edit_message
      # @return [Message]
      def edit(...)
        @interaction.edit_message(@id, ...)
      end
    end

    # Supplemental metadata about an interaction.
    class Metadata
      include Snowflake

      # @return [Integer] the type of the interaction.
      attr_reader :type

      # @return [User] the user that initiated the interaction.
      attr_reader :user

      # @return [User, nil] the user that the command was ran on.
      attr_reader :target_user

      # @return [Integer, nil] the ID of the message the command was ran on.
      attr_reader :target_message_id

      # @return [Metadata, nil] the metadata for the interaction that opened the modal.
      attr_reader :triggering_metadata

      # @return [Integer, nil] the ID of the message that contained the interactive message component.
      attr_reader :interacted_message_id

      # @return [Integer, nil] the ID the original response message; only present on follow-up messages.
      attr_reader :original_response_message_id

      # @!visibility private
      def initialize(data, message, bot)
        @bot = bot
        @message = message
        @id = data[:id].to_i
        @type = data[:type]
        @user = bot.ensure_user(data[:user]) if data[:user]
        @target_user = bot.ensure_user(data[:target_user]) if data[:target_user]
        @target_message_id = data[:target_message_id]&.to_i
        @triggering_metadata = Metadata.new(data[:triggering_interaction_metadata], @message, @bot) if data[:triggering_interaction_metadata]
        @interacted_message_id = data[:interacted_message_id]&.to_i
        @original_response_message_id = data[:original_response_message_id]&.to_i
        @integration_owners = data[:authorizing_integration_owners]&.transform_values(&:to_i)
      end

      # Check if the interaction was triggered by a user by installed the application.
      # @return [true, false] whether or not the application was installed by the user
      #   who initiated this interaction.
      def user_integration?
        @integration_owners[:'1'] == @user.id
      end

      # Check if the interaction was triggered by a guild by installed the application.
      # @return [true, false] whether or not the application was installed by the guild
      #   where this interaction originates from.
      def guild_integration?
        @integration_owners[:'0'] == @message.channel.guild_id
      end

      # Attempt to fetch the target message of the interaction.
      # @return [Message, nil] the target message of the interaction, or `nil` if it couldn't be found.
      def target_message
        return unless @target_message_id

        @target_message ||= @message.channel.message(@target_message_id)
      end

      # Attempt to fetch the message that contained the interatctive component.
      # @return [Message, nil] the interacted message with the component, or `nil` if it couldn't be found.
      def interacted_message
        return unless @interacted_message_id

        @interacted_message ||= @message.channel.message(@interacted_message_id)
      end

      # Attempt to fetch the original response message of the interaction.
      # @return [Message, nil] the original response message of the interaction, or `nil` if it couldn't be found.
      def original_response_message
        return unless @original_response_message_id

        @original_response_message ||= @message.channel.message(@original_response_message_id)
      end

      # @!method command?
      #  @return [true, false] whether or not the interaction metadata is for an application command.
      # @!method component?
      #  @return [true, false] whether or not the interaction metadata is for a message component.
      # @!method modal_submit?
      #  @return [true, false] whether or not the interaction metadata is for a modal submission.
      Interaction::TYPES.each do |name, value|
        define_method("#{name}?") do
          @type == value
        end
      end

      # @!visibility private
      def inspect
        "<Interactions::Metadata id=#{@id} type=#{@type} user_id=#{@user&.id} target_user_id=#{@target_user&.id}>"
      end
    end
  end
end
