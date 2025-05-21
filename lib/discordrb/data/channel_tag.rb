# frozen_string_literal: true

module Discordrb
  # A tag that can applied to a thread in a forum or media channel.
  class ChannelTag
    include IDObject

    # @return [String] The name of the tag.
    attr_reader :name

    # @return [Boolean] Whether the `MANAGE_THREADS` permission is required to add or remove this tag.
    attr_reader :moderated
    alias_method :moderated?, :moderated

    # @return [Emoji, String, nil] The custom emoji or unicode emoji of the tag. `Nil` for no emoji.
    attr_reader :emoji

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @channel = channel
      @id = data['id'].to_i
      @name = data['name']
      @moderated = data['moderated']
      @emoji = data['emoji_id'] ? bot.emoji(data['emoji_id']) : data['emoji_name']
    end

    # Update the name of this tag.
    # @param name [String] The new name of this tag.
    def name=(name)
      update_data(name: name)
    end

    # Set the moderated value of this tag.
    # @param moderated [Boolean] Whether the `MANAGE_THREADS` permission is required to add or remove this tag.
    def moderated=(moderated)
      update_data(moderated: moderated)
    end

    # Set the emoji of this tag.
    # @param emoji [Emoji, String, Integer, nil] The unicode emoji, custom emoji, or nil of this tag.
    def emoji=(emoji)
      emoji = case emoji
              when Emoji, Reaction
                emoji.id
              else
                emoji.to_i.zero? ? emoji : emoji.resolve_id
              end

      case emoji
      when Integer
        update_data(emoji_id: emoji, emoji_name: nil)
      when String
        update_data(emoji_id: nil, emoji_name: emoji)
      else
        update_data(emoji_id: nil, emoji_name: nil)
      end
    end

    private

    # @!visibility private
    def update_data(new_data)
      @channel.__send__(:update_tag_data, to_h.merge(new_data))
    end

    # @!visibility private
    def to_h
      data = {
        id: id,
        name: name,
        moderated: moderated,
      }

      case emoji
      when String
        data[:emoji_name] = emoji
      when Emoji
        data[:emoji_id] = emoji
      end

      data
    end
  end
end
