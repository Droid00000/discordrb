# frozen_string_literal: true

module Discordrb
  # An easy way to send messages.
  class Webhook
    include Snowflake

    # Mapping of webhook types.
    TYPES = {
      incoming: 1,
      follower: 2,
      interaction: 3
    }.freeze

    # @return [Integer] the type of the webhook.
    attr_reader :type

    # @return [String, nil] the default name of the webhook.
    attr_reader :name

    # @return [String, nil] the security token of the webhook.
    attr_reader :token

    # @return [String, nil] the CDN hash for the default avatar.
    attr_reader :avatar

    # @return [User, nil] the user who created the the webhook, or `nil`.
    attr_reader :creator

    # @return [Integer, nil] the application ID of the webhook's creator.
    attr_reader :application_id

    # @return [Integer, nil] the ID of the guild that the webhook is following.
    attr_reader :followed_guild_id

    # @return [Integer, nil] the ID of the channel that the webhook is following.
    attr_reader :followed_channel_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @type = data[:type]
      @name = data[:name]
      @token = data[:token]
      @avatar = data[:avatar]
      @guild_id = data[:guild_id]&.to_i
      @channel_id = data[:channel_id]&.to_i
      @creator = bot.ensure_user(data[:user]) if data[:user]
      @application_id = data[:application_id]&.to_i
      @followed_guild_id = data[:source_guild]&.[](:id)&.to_i
      @followed_channel_id = data[:source_channel]&.[](:id)&.to_i
    end

    # Get the guild that the webhook is for.
    # @return [Guild, nil] The guild that the webhook is for.
    def guild
      @bot.guild(@guild_id) if @guild_id
    end

    # Get the channel that the webhook is for.
    # @return [Channel, nil] The channel that the webhook is for.
    def channel
      @bot.channel(@channel_id) if @channel_id
    end

    # Permanently delete the webhook.
    # @param reason [String, nil] The reason to show in the guild's audit log for deleting the webhook.
    # @return [nil]
    def delete(reason: nil)
      if @token
        @bot.http.delete_webhook_with_token(@id, @token, reason: reason)
      else
        @bot.http.delete_webhook(@id, reason: reason)
      end

      nil
    end

    # Modify the properties of the webhook.
    # @param name [String] The new 1-80 character default name of the webhook.
    # @param avatar [File, #read, nil] The new default avatar of the webhook, or `nil`.
    # @param channel [Integer, String, Channel, nil] The channel that the webhook should be moved to.
    # @param reason [String, nil] The reason to show in the guild's audit log for modifying the webhook.
    # @return [nil]
    def modify(name: :undef, avatar: :undef, channel: :undef, reason: nil)
      data = {
        name: name,
        avatar: avatar.respond_to?(:read) ? Discordrb.encode64(avatar) : avatar,
        channel_id: channel == :undef ? channel : channel&.resolve_id,
        reason: reason
      }

      if channel != :undef || !@token
        update_data(@bot.http.modify_webhook(@id, **data))
      else
        update_data(@bot.http.modify_webhook_with_token(@id, @token, **data))
      end

      nil
    end

    # Utility method to get a webhook's default avatar URL.
    # @param format [String] The extension to return the URL in. Can be one of `webp`, `jpg`, or `png`.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String] The URL to the webhooks's default avatar.
    def avatar_url(format: 'webp', size: nil)
      if @avatar
        Assets[:user_avatar, @avatar, format, size:]
      else
        Assets[:default_user_avatar, @discriminator % 5, 'png']
      end
    end

    # @!method incoming?
    #   @return [true, false] whether or not the webhook is a standard webhook that anyone can use.
    # @!method follower?
    #   @return [true, false] whether or not the webhook is used to deliver crossposted announcements.
    # @!method interaction?
    #   @return [true, false] whether or not the webhook is used for bot interactions.
    TYPES.each do |name, value|
      define_method("#{name}?") { @type == value }
    end

    # Execute the webhook.
    # @example This sends a silent message with an embed.
    #   webhook.send_message(content: 'Hi <@171764626755813376>', flags: :suppress_notifications) do |builder|
    #     builder.add_embed do |embed|
    #       embed.title = 'The Ruby logo'
    #       embed.image = 'https://www.ruby-lang.org/images/header-ruby-logo.png'
    #     end
    #   end
    # @param content [String, nil] The content of the message. Should not be longer than 2000 characters or it will result in an error.
    # @param tts [true, false] Whether or not this message should be sent using Discord text-to-speech.
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds that should be attached to the message.
    # @param attachments [Array<File>] Files that can be referenced in embeds and components via `attachment://file.png`.
    # @param allowed_mentions [Hash, Discordrb::AllowedMentions, nil] Mentions that are allowed to ping on this message.
    # @param components [View, Array<#to_h>] Interaction components to associate with this message.
    # @param flags [Integer, Symbol, Array<Symbol, Integer>] Flags for this message. Currently only `:suppress_embeds` (1 << 2), `:suppress_notifications` (1 << 12), and `:uikit_components` (1 << 15) can be set.
    # @param has_components [true, false] Whether this message includes any V2 components. Enabling this disables sending content, polls, and embeds.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to the message.
    # @param thread [Channel, Integer, String, nil] The thread that the message should be sent to.
    # @param wait [true, false, nil] Whether to wait for the server to confirm that the message was sent.
    # @param tags [Array<ChannelTag, Integer, String>, nil] The IDs of the tags to apply to the thread in the forum or media channel.
    # @param thread_name [String, nil] The name of the thread to create in the forum or media channel.
    # @param name [String, nil] The overwritten name of the webhook for the message.
    # @param avatar [String, nil] The URL to the overwritten avatar of the webhook for the message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the builder overwrite method data.
    # @yieldparam view [Webhooks::View] An optional component builder. Arguments passed to the builder overwrite method data.
    # @raise [Discordrb::Errors::NoPermission] If the webhook did not include its token when fetched.
    # @return [Message, nil] The message that was created, or `nil` if `wait:` was `false`.
    def send_message(content: nil, tts: false, embeds: [], attachments: nil, allowed_mentions: nil, components: nil, flags: 0, has_components: false, poll: nil, thread: nil, wait: true, tags: nil, thread_name: nil, name: nil, avatar: nil)
      raise Discordrb::Errors::UnauthorizedWebhook, 'Sending a webhook message requires a token' unless @token

      builder = Discordrb::Webhooks::Builder.new
      view = Discordrb::Webhooks::View.new

      builder.tts = tts
      builder.poll = poll
      builder.content = content
      embeds&.each { |embed| builder << embed }
      builder.allowed_mentions = allowed_mentions

      yield(builder, view) if block_given?

      flags = [*flags].reduce(0) { |sum, bit| sum | (Message::FLAGS[bit] || bit.to_i) }
      flags |= (1 << 15) if has_components
      builder = builder.to_json_hash
      view = view.to_a
      view = nil unless view.any?
      components = view || components&.to_a

      data = {
        wait: wait,
        thread_name: thread_name || :undef,
        thread_id: thread&.resolve_id || :undef,
        content: builder[:content] || :undef,
        tts: tts,
        embeds: builder[:embeds] == [] ? :undef : builder[:embeds],
        files: attachments&.map { |file| file.is_a?(Hash) ? file : { file: file } } || :undef,
        allowed_mentions: builder[:allowed_mentions] || :undef,
        components: components == [] ? :undef : (components || :undef),
        flags: flags.zero? ? :undef : flags,
        poll: builder[:poll] || :undef,
        applied_tags: tags ? [*tags].map(&:resolve_id) : :undef,
        with_components: flags.anybits?(Message::FLAGS[:uikit_components]) || false,
        username: name || :undef,
        avatar_url: avatar || :undef
      }

      response = @bot.http.execute_webhook(@id, @token, **data)
      wait ? Message.new(response, @bot) : nil
    end

    alias_method :execute, :send_message

    # Edit a message that was sent by the webhook.
    # @param message [Message, Integer, String] The message that should be edited.
    # @param content [String, nil] The content of the message. Should not be longer than 2000 characters or it will result in an error.
    # @param embeds [Array<Hash, Webhooks::EmbedBuilder>, nil] The embeds that should be attached to the message.
    # @param attachments [Array<File, Attachment, #read>, nil] The files that can be referenced in embeds and components via `attachment://file.png`.
    # @param allowed_mentions [Hash, Discordrb::AllowedMentions, nil] The mentions that are allowed to ping on the message.
    # @param flags [Integer, Symbol, Array<Symbol, Integer>] The new flags to set for the message.
    # @param components [View, Array<#to_h>, nil] The bot components to associate with the message.
    # @param thread [Channel, Integer, String] The thread that the webhook message was sent in.
    # @param has_components [true] Whether or not the message will include any V2 components. Enabling this disables sending content and embeds.
    # @param with_components [true, false] Whether to respect the components field of the request for webhooks that aren't owned by an application.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Any arguments passed to the builder overwrite method data.
    # @yieldparam view [Webhooks::View] An optional message component builder. Any arguments passed to the builder overwrite method data.
    # @raise [Discordrb::Errors::NoPermission] If the webhook did not include its token when fetched.
    # @return [Message] The updated message.
    def modify_message(
      message:, content: :undef, embeds: :undef, flags: :undef, allowed_mentions: :undef,
      components: :undef, attachments: :undef, has_components: :undef, thread: :undef, with_components: :undef
    )
      raise Discordrb::Errors::UnauthorizedWebhook, 'Editing a webhook message requires a token' unless @token

      view = Discordrb::Webhooks::View.new
      builder = Discordrb::Webhooks::Builder.new

      builder.content = content
      [*embeds].each { |item| builder << item } unless embeds == :undef
      builder.allowed_mentions = allowed_mentions unless allowed_mentions == :undef
      yield(builder, view) if block_given?

      view = view.to_a
      view = nil unless view.any?
      builder = builder.to_json_hash

      data = {
        content: builder[:content],
        with_components: with_components,
        allowed_mentions: builder[:allowed_mentions],
        thread_id: thread == :undef ? :undef : thread&.resolve_id,
        components: view || (components == :undef ? components : components&.to_a),
        embeds: block_given? && builder[:embeds]&.any? ? builder[:embeds] : embeds
      }

      (data[:thread_id] = message.channel.id) if message.is_a?(Message) && message.channel.thread?

      if attachments != :undef
        attachments = [attachments] unless attachments.is_a?(Array) || attachments.is_a?(Set)

        data[:files] = attachments&.map&.with_index do |attachment, index|
          if attachment.is_a?(Hash)
            attachment
          elsif attachment.respond_to?(:read)
            { file: attachment }
          elsif attachment.respond_to?(:resolve_id)
            { id: attachment.resolve_id }
          else
            raise ArgumentError, "Invalid attachment type: ('#{attachment.class}', #{index})"
          end
        end
      end

      if flags != :undef || has_components == true
        flags = if message.is_a?(Message) && flags == :undef
                  message.flags
                elsif flags == :undef
                  0
                else
                  [*flags].reduce(0) { |sum, bit| sum | (Message::FLAGS[bit] || bit.to_i) }
                end

        flags |= Message::FLAGS[:uikit_components] if has_components == true

        if flags.anybits?(Message::FLAGS[:uikit_components])
          data.merge!({ content: nil, poll: nil, embeds: [] })
        end

        data[:flags] = flags
      end

      response = @bot.http.edit_webhook_message(@id, @token, message.resolve_id, **data)
      message.is_a?(Message) ? message.tap { message.update_data(response) } : Message.new(response, @bot)
    end

    # Delete a message that was sent by the webhook.
    # @param message [Integer, String, Message] The message that should be deleted.
    # @param thread [Channel, Integer, String, nil] The thread that the message was sent in.
    # @raise [Discordrb::Errors::NoPermission] If the webhook did not include its token when fetched.
    # @return [nil]
    def delete_message(message, thread: nil)
      (thread ||= message.channel.id) if message.is_a?(Message) && message.channel.thread?
      raise Discordrb::Errors::UnauthorizedWebhook, 'Deleting a webhook message requires a token.' unless @token

      @bot.http.delete_webhook_message(@id, @token, message.resolve_id, thread_id: thread&.resolve_id || :undef)
      nil
    end

    # @!visibility private
    def inspect
      "<Webhook id=#{@id} name=\"#{@name}\" type=#{@type}>"
    end

    private

    # @!visibility private
    def update_data(new_data)
      @name = new_data[:name]
      @avatar = new_data[:avatar]
      @channel_id = new_data[:channel_id]&.to_i
      @creator = @bot.ensure_user(new_data[:user]) if new_data[:user]
    end
  end
end
