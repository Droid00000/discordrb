# frozen_string_literal: true

module Discordrb
  # A partial and immutable copy of a message that has been forwarded.
  class Snapshot
    # @return [Integer] the message type of the message snapshot.
    attr_reader :type

    # @return [String] the text content of the message snapshot.
    attr_reader :content

    # @return [Array<Embed>] the embeds attached to the message snapshot.
    attr_reader :embeds

    # @return [Array<Attachment>] the files attached to the message snapshot.
    attr_reader :attachments

    # @return [Time, nil] the time at which the message snapshot was edited.
    attr_reader :edited_at

    # @return [Time] the time at when the snapshot's source message was created.
    attr_reader :creation_time

    # @return [Integer] the flags that have been set on the message snapshot.
    attr_reader :flags

    # @return [Array<User>] the users that were mentioned in the message snapshot.
    attr_reader :mentions

    # @return [Array<Component>] the interaction components associated with the message snapshot.
    attr_reader :components

    # @return [Array<Sticker::Item>] the stickers included in the message snapshot.
    attr_reader :stickers

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @type = data[:type]
      @flags = data[:flags] || 0
      @content = data[:content]
      @mention_roles = data[:mention_roles]&.map(&:resolve_id) || []
      @embeds = data[:embeds]&.map { |embed| Embed.new(embed, @bot) } || []
      @attachments = data[:attachments]&.map { |file| Attachment.new(file, self, @bot) } || []
      @creation_time = data[:timestamp] ? Time.iso8601(data[:timestamp]) : nil
      @edited_at = data[:edited_timestamp] ? Time.iso8601(data[:edited_timestamp]) : nil
      @mentions = data[:mentions]&.map { |mention| @bot.ensure_user(mention) } || []
      @components = data[:components]&.map { |component| Components.from_data(component, @bot) } || []
      @stickers = (data[:sticker_items] || data[:stickers])&.map { |item| Sticker::Item.new(item, @bot) } || []
    end

    # Check whether the message snapshot has been edited.
    # @return [true, false] whether the snapshot was edited or not.
    def edited?
      !@edited_at.nil?
    end

    # Get the custom emojis that were used in the message snapshot.
    # @return [Array<Emoji>] The custom emojis that were used in the message snapshot.
    def emojis
      return (@emojis || []) if @emojis || !@content || @content.empty?

      @emojis = []

      @content.scan(/<(a?):(\w{2,32}):(\d{15,32})>/) do |type, name, e_id|
        e_id = e_id.to_i
        animated = (type == 'a')
        @emojis << (@bot.emoji(e_id) || Emoji.new({ id: e_id, name:, animated: }))
      end

      @emojis
    end

    # Get the formatted timestamps contained in the message snapshot..
    # @return [Array<TimestampMarkdown>] The formatted timestamps in the message snapshot.
    def timestamps
      return (@fmt_timestamps || []) if @fmt_timestamps || !@content || @content.empty?

      @fmt_timestamps = []

      @content.scan(/<t:(-?\d{1,13})(?::(t|T|d|D|f|F|s|S|R))?>/) do |time, specifier|
        # If it's not between these values, Discord won't show it, so don't even bother.
        if (time = time.to_i).between?(-8_640_000_000_000, 8_640_000_000_000)
          @fmt_timestamps << TimestampMarkdown.new(Time.at(time), specifier)
        end
      end

      @fmt_timestamps
    end

    # Get the roles that were mentioned in the message snapshot.
    # @return [Array<Role>] the roles that were mentioned in the message snapshot.
    # @note this can only resolve roles in guilds that the bot has access to via {Bot#guilds}.
    def role_mentions
      return [] if @mention_roles.empty?

      return @role_mentions if @role_mentions

      found = nil

      @role_mentions = @mention_roles.filter_map do |role_id|
        if found
          found.role(role_id)
        else
          @bot.guilds.each do |guild|
            role = guild.role(role_id)
            next unless role

            found = guild
            break role
          end
        end
      end
    end

    # Get the buttons that were used in the message snapshot.
    # @return [Array<Components::Button>] the button components used in the message snapshot.
    def buttons
      buttons = @components.flat_map do |component|
        case component
        when Components::Button
          component
        when Components::Section
          component.accessory if component.accessory.is_a?(Components::Button)
        when Components::ActionRow, Components::Container
          component.buttons
        end
      end

      buttons.compact
    end

    # @see Discordrb::Message::FLAGS
    Message::FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end

    # @see Discordrb::Message::TYPES
    Message::TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end
  end
end
