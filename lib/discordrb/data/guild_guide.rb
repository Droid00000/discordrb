# frozen_string_literal: true

module Discordrb
  # The new member welcome experience, aka the server guide.
  class GuildGuide
    # @return [Guild] the guild associated with the guild guide.
    attr_reader :guild

    # @return [true, false] whether or not the guild guide is enabled.
    attr_reader :enabled
    alias :enabled? :enabled

    # @return [WelcomeMessage] the welcome message shown to new members.
    attr_reader :welcome_message

    # @return [Array<ResourceChannel>] the guild's read-only resource channels.
    attr_reader :resource_channels

    # @return [Array<NewMemberAction>] the actions that new members are prompted to do.
    attr_reader :new_member_actions

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      update_data(data)
    end

    # Check if two guild guides are equivalent.
    # @param other [Object] The object to compare against for equality.
    # @return [true, false] Whether or not the two objects are equivalent.
    def ==(other)
      other.is_a?(GuildGuide) ? @guild == other.guild : false
    end

    alias :eql? :==

    # @!visibility private
    def update_data(new_data)
      @enabled = new_data[:enabled]
      @welcome_message = WelcomeMessage.new(new_data[:welcome_message], self, @bot)
      @resource_channels = new_data[:resource_channels].map { |item| ResourceChannel.new(item, self, @bot) }
      @new_member_actions = new_data[:new_member_actions].map { |item| NewMemberAction.new(item, self, @bot) }
    end

    # The message shown to new guild members.
    class WelcomeMessage
      # @return [String, nil] the content of the welcome message.
      attr_reader :content

      # @return [Array<Integer>] the user IDs of the welcome message authors.
      attr_reader :author_ids

      # @!visibility private
      def initialize(data, guide, bot)
        @bot = bot
        @guide = guide
        @authors = nil
        @content = data[:message] == '' ? nil : data[:message]
        @author_ids = data[:author_ids]&.map(&:resolve_id) || []
      end

      # Retrieve the authors of the welcome message.
      # @return [Array<User>] The authors of the welcome message.
      def authors
        @authors ||= @author_ids.filter_map { |id| @bot.user(id) }
      end

      # Check if two welcome messages are equivalent.
      # @param other [Object] The object to compare against for equality.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        return false unless other.is_a?(WelcomeMessage)

        @author_ids == other.author_ids && @content == other.content
      end

      alias :eql? :==
    end

    # An action that a new guild member is prompted to complete.
    class NewMemberAction
      TYPES = {
        view_channel: 0,
        send_message: 1
      }.freeze

      # @return [Integer] the type of action the member should complete.
      attr_reader :type

      # @return [String, nil] the hash of the icon representing the action.
      attr_reader :icon

      # @return [String] the title of the action; maximum of 60 characters.
      attr_reader :title

      # @return [Emoji, nil] the guild or unicode emoji representing the action.
      attr_reader :emoji

      # @return [Integer] the ID of the channel where the action should be completed.
      attr_reader :channel_id

      # @return [String, nil] the description of the action; maximum of 200 characters.
      attr_reader :description

      # @!visibility private
      def initialize(data, guide, bot)
        @bot = bot
        @guide = guide
        @channel = nil
        @icon = data[:icon]
        @type = data[:action_type]
        @title = data[:title]
        @emoji = Emoji.new(data[:emoji], bot, guide.guild) if data[:emoji]
        @channel_id = data[:channel_id].to_i
        @description = data[:description] == '' ? nil : data[:description]
      end

      # Get the channel where the action can be completed.
      # @return [Channel, nil] The channel where the action can be completed.
      def channel
        @channel ||= @bot.channel(@channel_id)
      end

      # @!method view_channel?
      #   @return [true, false] whether members must open the channel to complete the action.
      # @!method send_message?
      #   @return [true, false] whether members must send a message in the channel to complete the action.
      TYPES.each do |name, value|
        define_method("#{name}?") { @type == value }
      end

      # Check if two new member actions are equivalent.
      # @param other [Object] The object to compare against for equality.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        other.is_a?(NewMemberAction) ? @channel_id == other.channel_id : false
      end

      alias :eql? :==
      alias :view? :view_channel?
      alias :send? :send_message?

      # Utility method to get a new member action's custom icon URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
      # @param size [Integer, nil] The size of the icon. You can specify any number from 0-4096 that's a power of two to override this.
      # @return [String, nil] The URL to the new member action's custom icon, or `nil` if the new member action doesn't have a custom icon set.
      def icon_url(format: 'webp', size: nil)
        Assets[:guild_new_member_action_icon, @channel_id, @icon, format, size:] if @icon
      end
    end

    # A read-only resource channel for the guild guide.
    class ResourceChannel
      # @return [String, nil] the hash of the icon representing the resource channel.
      attr_reader :icon

      # @return [String] the title of the resource channel; maximum of 60 characters.
      attr_reader :title

      # @return [Emoji, nil] the guild or unicode emoji representing the resource channel.
      attr_reader :emoji

      # @return [Integer] the ID of the channel that the resource channel is a pointer to.
      attr_reader :channel_id

      # @return [String, nil] the description of the resource channel; maximum of 200 characters.
      attr_reader :description

      # @!visibility private
      def initialize(data, guide, bot)
        @bot = bot
        @guide = guide
        @channel = nil
        @icon = data[:icon]
        @title = data[:title]
        @emoji = Emoji.new(data[:emoji], bot, guide.guild) if data[:emoji]
        @channel_id = data[:channel_id].to_i
        @description = data[:description] == '' ? nil : data[:description]
      end

      # Get the channel that the resource channel references.
      # @return [Channel, nil] The channel that the resource channel references.
      def channel
        @channel ||= @bot.channel(@channel_id)
      end

      # Check if two resource channels are equivalent.
      # @param other [Object] The object to compare against for equality.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        other.is_a?(ResourceChannel) ? @channel_id == other.channel_id : false
      end

      alias :eql? :==

      # Utility method to get a resource channel's custom icon URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
      # @param size [Integer, nil] The size of the icon. You can specify any number from 0-4096 that's a power of two to override this.
      # @return [String, nil] The URL to the resource channel's custom icon, or `nil` if the resource channel doesn't have a custom icon set.
      def icon_url(format: 'webp', size: nil)
        Assets[:guild_resource_channel_icon, @channel_id, @icon, format, size:] if @icon
      end
    end
  end
end
