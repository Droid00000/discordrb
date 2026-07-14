# frozen_string_literal: true

module Discordrb
  # A forum or media tag that can be applied to threads.
  class ChannelTag
    include Snowflake

    # @return [String] the 1-20 character name of the channel tag.
    attr_reader :name

    # @return [Channel] the channel associated with the channel tag.
    attr_reader :channel

    # @return [true, false] whether or not the channel tag is moderated.
    attr_reader :moderated
    alias moderated? moderated

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @channel = channel
      @id = data[:id].to_i
      update_data(data)
    end

    # Get the emoji of the channel tag.
    # @return [Emoji, nil] the emoji of the channel tag, or `nil` if no emoji has been set.
    def emoji
      @emoji_id ? @channel.guild.emoji(@emoji_id) : @emoji_name
    end

    # Modify the properties of the channel tag.
    # @param name [String] The new 1-20 character name of the channel tag.
    # @param emoji [Emoji, Integer, String, nil] The new emoji of the channel tag.
    # @param moderated [true, false] Whether or not the channel tag should be moderated.
    # @param reason [String, nil] The reason to show in the audit log for modifying the tag.
    # @return [nil]
    def modify(name: :undef, emoji: :undef, moderated: :undef, reason: nil)
      new_data = {
        name: name,
        moderated: moderated,
        **(Emoji.build_hash(emoji) if emoji != :undef)
      }.reject { |_, value| value == :undef }

      @channel.update_forum_tags(to_h.merge!(new_data), reason)
    end

    # Permenantly delete the channel tag.
    # @param reason [String, nil] The reason to show in the audit log for deleting the tag.
    # @return [nil]
    def delete(reason: nil)
      @channel.update_forum_tags({ id: @id, _d: true }, reason)
    end

    # @!visibility private
    def to_h
      {
        id: @id,
        name: @name,
        emoji_id: @emoji_id,
        moderated: @moderated,
        emoji_name: @emoji_name&.name
      }
    end

    # @!visibility private
    def inspect
      "<ChannelTag id=#{@id} name=\"#{@name}\" moderated=#{@moderated}>"
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data[:name]
      @moderated = new_data[:moderated]
      @emoji_id = new_data[:emoji_id]&.to_i
      @emoji_name = new_data[:emoji_name] ? Emoji.new({ name: new_data[:emoji_name] }, @bot) : nil
    end

    # @!visibility private
    def self.build_hash(
      name:, moderated:, emoji: nil
    )
      {
        name: name,
        moderated: moderated || false,
        **Emoji.build_hash(emoji).compact
      }
    end
  end
end
