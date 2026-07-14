# frozen_string_literal: true

require 'discordrb/version'
require 'discordrb/bot'
require 'discordrb/commands/command_bot'
require 'discordrb/logger'

# All discordrb functionality, to be extended by other files.
module Discordrb
  Thread.current[:discordrb_name] = 'main'

  # The default debug logger used by discordrb.
  LOGGER = Logger.new(ENV.fetch('DISCORDRB_FANCY_LOG', false))

  # The Unix timestamp that Discord IDs are based on.
  DISCORD_EPOCH = 1_420_070_400_000

  # Used to declare what events you wish to recieve from Discord.
  # @see https://discord.com/developers/docs/topics/gateway#gateway-intents
  INTENTS = {
    guilds: 1 << 0,
    guild_members: 1 << 1,
    guild_moderation: 1 << 2,
    guild_expressions: 1 << 3,
    guild_integrations: 1 << 4,
    guild_webhooks: 1 << 5,
    guild_invites: 1 << 6,
    guild_voice_states: 1 << 7,
    guild_presences: 1 << 8,
    guild_messages: 1 << 9,
    guild_message_reactions: 1 << 10,
    guild_message_typing: 1 << 11,
    direct_messages: 1 << 12,
    direct_message_reactions: 1 << 13,
    direct_message_typing: 1 << 14,
    guild_message_content: 1 << 15,
    guild_scheduled_events: 1 << 16,
    guild_automod: 1 << 20,
    guild_automod_execution: 1 << 21,
    guild_message_polls: 1 << 24,
    direct_message_polls: 1 << 25
  }.freeze

  # All available intents.
  # @see https://discord.com/developers/docs/topics/gateway#gateway-intents
  ALL_INTENTS = INTENTS.values.reduce(&:|)

  # All unprivileged intents.
  # @see https://discord.com/developers/docs/topics/gateway#privileged-intents
  UNPRIVILEGED_INTENTS = ALL_INTENTS & ~(INTENTS[:guild_members] | INTENTS[:guild_presences] | INTENTS[:guild_message_content])

  # No intents.
  # @see https://discord.com/developers/docs/topics/gateway#privileged-intents
  NO_INTENTS = 0

  # Compares two objects based on IDs - either the objects' IDs are equal, or one object is equal to the other's ID.
  def self.id_compare?(one_id, other)
    other.respond_to?(:resolve_id) ? (one_id.resolve_id == other.resolve_id) : (one_id == other)
  end

  # @deprecated Please use {Discordrb.id_compare?}
  singleton_class.alias_method :id_compare, :id_compare?

  # The maximum length a Discord message can have.
  CHARACTER_LIMIT = 2000

  # Splits a message into chunks of 2000 characters. Attempts to split by lines if possible.
  # @param msg [String] The message to split.
  # @return [Array<String>] The message split into chunks.
  def self.split_message(msg)
    # If the messages is empty, return an empty array
    return [] if msg.empty?

    # Split the message into lines
    lines = msg.lines

    # Turn the message into a "triangle" of consecutively longer slices, for example the array [1,2,3,4] would become
    # [
    #  [1],
    #  [1, 2],
    #  [1, 2, 3],
    #  [1, 2, 3, 4]
    # ]
    tri = (0...lines.length).map { |i| lines.combination(i + 1).first }

    # Join the individual elements together to get an array of strings with consecutively more lines
    joined = tri.map(&:join)

    # Find the largest element that is still below the character limit, or if none such element exists return the first
    ideal = joined.max_by { |e| e.length > CHARACTER_LIMIT ? -1 : e.length }

    # If it's still larger than the character limit (none was smaller than it) split it into the largest chunk without
    # cutting words apart, breaking on the nearest space within character limit, otherwise just return an array with one element
    ideal_ary = ideal.length > CHARACTER_LIMIT ? ideal.split(/(.{1,#{CHARACTER_LIMIT}}\b|.{1,#{CHARACTER_LIMIT}})/o).reject(&:empty?) : [ideal]

    # Slice off the ideal part and strip newlines
    rest = msg[ideal.length..].strip

    # If none remains, return an empty array -> we're done
    return [] unless rest

    # Otherwise, call the method recursively to split the rest of the string and add it onto the ideal array
    ideal_ary + split_message(rest)
  end

  # Create a channel tag that can be used when {Channel#modify modifying}
  #   or {Guild#create_channel creating} a forum channel.
  # @example This creates a channel tag.
  #   Discordrb::ChannelTag(name: "Bug Report", moderated: false, emoji: "🐛")
  # @overload ChannelTag(name:, moderated:, emoji: nil)
  #   @param name [String] the 1-20 character name of the tag.
  #   @param moderated [true, false] Whether the tag should be moderated.
  #   @param emoji [Integer, String, Emoji, nil] The emoji to set for the tag.
  # @return [Hash] The channel tag with the given data.
  def self.ChannelTag(...)
    ChannelTag.build_hash(...)
  end

  # Create an overwrite that can be used when {Channel#modify modifying}
  #   or {Guild#create_channel creating} a channel.
  #
  #   Permissions can be passed as KWARGS. A value of `true` will allow the
  #   permission (green check), and a value of `false` will deny the permission
  #   (red X). A permission is neutral (grey slash), if it is neither allowed or denied.
  # @example This creates an overwrite for a role.
  #   Discordrb::Overwrite(
  #     role: 80528701850124288,
  #     use_application_commands: true,
  #     set_voice_channel_status: false
  #   )
  # @example This creates an overwrite for a member.
  #   Discordrb::Overwrite(
  #     member: 171764626755813376,
  #     use_application_commands: true,
  #     set_voice_channel_status: false
  #   )
  # @overload Overwrite(role: nil, member: nil, **permissions)
  #   @param role [Role, Integer, String, nil] The role that the overwrite should target.
  #   @param member [User, Member, Integer, String, nil] The member that the overwrite should target.
  # @return [Hash] The overwrite for the target with the given permissions.
  def self.Overwrite(...)
    Overwrite.build_hash(...)
  end

  # Create a timestamp using Discord's mention syntax.
  # @example
  #   Discordrb.timestamp(Time.now, :short_time) # => "<t:1632146954:t>"
  # @param time [Time, Integer] The time to create the timestamp from, or a unix timestamp integer.
  # @param style [Symbol, String] One of the keys from {TimestampMarkdown::STYLES} or a string with the style.
  # @return [String] The time formatted as a Discord timestamp.
  def self.timestamp(time, style = nil)
    return "<t:#{time.to_i}>" unless style

    "<t:#{time.to_i}:#{TimestampMarkdown::STYLES[style] || style}>"
  end

  # A utility method to base64 encode a file like-object into a data URI.
  # @param file [File, #read] A file like object that responds to `#read`.
  # @return [String] The file object represented in its Base64 data URI form.
  # @raise [ArgumentError] If the file-like object does not respond to `#read`.
  def self.encode64(file)
    unless file.respond_to?(:read)
      raise ArgumentError, 'File or file-like object must respond to {#read}.'
    end

    "data:#{sniff_mime_type(file)};base64,#{Base64.strict_encode64(file.read)}"
  end

  # A utility method to determine the content type of a file.
  # @param file [File, #read] A file-like object that responds to `#read`.
  # @return [String] The content type of the file. The only content types that are
  #   currently supported include: `audio/ogg`, `image/png`, `image/gif`, `image/webp`,
  #   `audio/mpeg`, `image/avif`, `image/jpeg`, and `application/json`.
  # @raise [ArgumentError] If the content type of the file was unable to be determined.
  def self.sniff_mime_type(file)
    bytes = file.read(12).tap { file.rewind }

    if bytes.start_with?('OggS'.b)
      'audio/ogg'
    elsif bytes.start_with?("\x89PNG\r\n\x1A\n".b)
      'image/png'
    elsif bytes.start_with?('GIF87a'.b, 'GIF89a'.b)
      'image/gif'
    elsif bytes.start_with?('RIFF'.b) && bytes[8, 4] == 'WEBP'.b
      'image/webp'
    elsif bytes.start_with?("\xFF\xFB".b, "\xFF\xF3".b, "\xFF\xF2".b, 'ID3'.b)
      'audio/mpeg'
    elsif bytes[4, 4] == 'ftyp'.b && ['avif'.b, 'avis'.b].include?(bytes[8, 4])
      'image/avif'
    elsif bytes.start_with?("\xFF\xD8\xFF".b) || ['JFIF'.b, 'Exif'.b].include?(bytes[6, 4])
      'image/jpeg'
    elsif bytes.start_with?('{'.b)
      'application/json'
    else
      raise ArgumentError, 'Unable to determine the exact content type of the provided file.'
    end
  end
end

# In discordrb, Integer and {String} are monkey-patched to allow for easy resolution of IDs
class Integer
  # @return [Integer] The Discord ID represented by this integer, i.e. the integer itself
  def resolve_id
    self
  end
end

# In discordrb, {Integer} and String are monkey-patched to allow for easy resolution of IDs
class String
  # @return [Integer] The Discord ID represented by this string, i.e. the string converted to an integer
  def resolve_id
    to_i
  end
end
