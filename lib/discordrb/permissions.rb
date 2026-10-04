# frozen_string_literal: true

module Discordrb
  # Represents a set of Discord permissions.
  class Permissions
    # Mapping of bit positions to permission names.
    FLAGS = {
      # Bit => Permission # Value
      0 => :create_instant_invite,        # 1
      1 => :kick_members,                 # 2
      2 => :ban_members,                  # 4
      3 => :administrator,                # 8
      4 => :manage_channels,              # 16
      5 => :manage_guild,                 # 32
      6 => :add_reactions,                # 64
      7 => :view_audit_log,               # 128
      8 => :priority_speaker,             # 256
      9 => :stream,                       # 512
      10 => :read_messages,               # 1024
      11 => :send_messages,               # 2048
      12 => :send_tts_messages,           # 4096
      13 => :manage_messages,             # 8192
      14 => :embed_links,                 # 16384
      15 => :attach_files,                # 32768
      16 => :read_message_history,        # 65536
      17 => :mention_everyone,            # 131072
      18 => :use_external_emojis,         # 262144
      19 => :view_guild_insights,         # 524288
      20 => :connect,                     # 1048576
      21 => :speak,                       # 2097152
      22 => :mute_members,                # 4194304
      23 => :deafen_members,              # 8388608
      24 => :move_members,                # 16777216
      25 => :use_voice_activity,          # 33554432
      26 => :change_nickname,             # 67108864
      27 => :manage_nicknames,            # 134217728
      28 => :manage_roles,                # 268435456, also Manage Permissions
      29 => :manage_webhooks,             # 536870912
      30 => :manage_expressions,          # 1073741824
      31 => :use_application_commands,    # 2147483648
      32 => :request_to_speak,            # 4294967296
      33 => :manage_scheduled_events,     # 8589934592
      34 => :manage_threads,              # 17179869184
      35 => :create_public_threads,       # 34359738368
      36 => :create_private_threads,      # 68719476736
      37 => :use_external_stickers,       # 137438953472
      38 => :send_messages_in_threads,    # 274877906944
      39 => :use_embedded_activities,     # 549755813888
      40 => :moderate_members,            # 1099511627776
      41 => :view_monetization_analytics, # 2199023255552
      42 => :use_soundboard,              # 4398046511104
      43 => :create_expressions,          # 8796093022208
      44 => :create_scheduled_events,     # 17592186044416
      45 => :use_external_sounds,         # 35184372088832
      46 => :send_voice_messages,         # 70368744177664
      48 => :set_voice_channel_status,    # 281474976710656
      49 => :send_polls,                  # 562949953421312
      50 => :use_external_apps,           # 1125899906842624
      51 => :pin_messages,                # 2251799813685248
      52 => :bypass_slowmode              # 4503599627370496
    }.freeze

    # @!visibility private
    IMPLICIT = {
      send_messages: 6_262_955_671_212_032,
      stage: 2_952_866_897 | 12_906_922_496,
      voice: 2_952_866_897 | 286_431_435_031_296,
      text: 2_952_866_897 | 2_252_744_706_490_368
    }.freeze

    # @!visibility private
    MASKS = FLAGS.to_h { |bit, name| [name, 1 << bit] }.freeze

    # @!visibility private
    ALL = MASKS.values.reduce(0) { |total, bit| total | bit }.freeze

    # @return [Integer] the raw bitfield representing the permissions.
    attr_reader :bits
    alias :to_i :bits

    # Create a new permissions object.
    # @example Create a new permissions object for a list of specific permissions.
    #   Permissions.new([:read_messages, :connect, :speak])
    # @example Create a blank permissions object and then add specific permissions.
    #   permission = Permissions.new
    #   permission.bypass_slowmode = true
    #   permission.use_slash_commands = true
    #   permission.send_messages_in_threads = true
    # @param bits [String, Integer, Array<Symbol, String>] The raw bitfield that should
    #   be initially set, or a collection of permission symbols.
    def initialize(bits = 0)
      self.bits = bits
    end

    MASKS.each do |name, mask|
      define_method("#{name}=") do |value|
        value ? (@bits |= mask) : (@bits &= ~mask)
      end

      define_method("#{name}?") { @bits.anybits?(mask) }
    end

    alias :administrate? :administrator?
    alias :administrate= :administrator=

    # Compare two permission objects based off of their bitfield.
    # @param other [Permissions, Object] The permissions object to compare this one against.
    # @return [true, false] Whether or not the two permission objects represent the same bitfield.
    def ==(other)
      other.is_a?(Permissions) ? (@bits == other.bits) : false
    end

    alias :eql? :==

    # Return the corresponding bitfield for an array of permission symbols.
    # @example Get the bits for permissions that could send voice messages and manage channels.
    #   Permissions.bits([:send_voice_messages, :manage_channels]) # => 3146752
    # @param collection [Array<Symbol, String>] The permission symbols to compute the bitfield for.
    # @return [Integer] The corresponding bitfield value for the provided permissions.
    def self.bits(collection)
      collection.reduce(0) { |sum, element| sum | MASKS[element.to_sym] }
    end

    # Set the bits that the permission object should represent.
    # @param bits [String, Integer, Array<Symbol, String>] The raw bitfield that
    #   should be initially set, or a collection of permission symbols.
    # @return [Integer] The new bitfield value that was set for the permissions object.
    def bits=(bits)
      @bits = bits.respond_to?(:map) ? Permissions.bits(bits) : bits.to_i
    end

    # Get the permissions for the permission object as an array of symbols.
    # @example Get the permissions for the bitfield value "274877908992"
    #   permissions = Permissions.new(274877908992)
    #   permissions.defined_permissions # => [:send_messages, :send_messages_in_threads]
    # @return [Array<Symbol>] The symbols for the permissions that represent the permissions object.
    def defined_permissions
      MASKS.filter_map { |name, value| @bits.anybits?(value) ? name : nil }
    end
  end

  # Mixin to calculate permissions for guild members.
  module PermissionCalculator
    # Get the permissions that the member has.
    # @param channel [Integer, String, Channel, nil] The channel that should be used to calculate
    #   permissions. If this is `nil`, then the user's overall guild permissions will be calculated.
    # @return [Integer] The bitwise value that represents the permissions the member has in the guild.
    def permissions(channel = nil)
      if @permissions && @interaction_channel_id == channel&.resolve_id
        return @permissions.bits
      end

      return Permissions::ALL if owner?

      base = guild.everyone_role.permissions.bits

      roles.each do |role|
        base |= role.permissions.bits

        return Permissions::ALL if role.permissions.administrator?
      end

      (channel = @bot.channel(channel)) if channel && !channel.is_a?(Channel)

      computed = if channel
                   compute_overwrites(base, channel)
                 else
                   base
                 end

      # Members in timeout lose all of their permissions except for
      # the `:read_messages` and the `:read_message_history` permissions.
      timeout? ? Permissions.bits(%i[read_messages read_message_history]) : computed
    end

    # Checks whether this user can do the particular action, regardless of whether it has the permission defined, through for example being
    #   the guild owner or having the Manage Roles permission.
    # @param permission [Symbol] The permission that should be checked. See also {Permissions::FLAGS} for a list.
    # @param channel [Channel, nil] If channel overrides should be checked too, this channel specifies where the overrides should be checked.
    # @example Check if the bot can send messages to a specific channel in a guild.
    #   bot_profile = bot.profile.member(event.guild)
    #   can_send_messages = bot_profile.permission?(:send_messages, channel)
    # @return [true, false] Whether or not this user has the permission.
    def permission?(permission, channel = nil)
      # Interaction events already give us the permissions (including implicit
      # permissions as well), so we can just delegate to that and call it a day.
      if @permissions && @interaction_channel_id == channel&.resolve_id
        return @permissions.__send__(:"#{permission}?")
      end

      if channel && !channel.is_a?(Channel)
        channel = @bot.channel(channel.resolve_id)
      end

      computed = permissions(channel)

      if channel&.thread? && permission == :send_messages
        computed.anybits?(Permissions::MASKS[:send_messages_in_threads])
      else
        computed.anybits?(Permissions::MASKS[permission])
      end
    end

    # @!method can_kick_members?
    #   Check if the member has the `KICK_MEMBERS` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_ban_members?
    #   Check if the member has the `BAN_MEMBERS` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_administrator?
    #   Check if the member has the `ADMINISTRATOR` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_change_nickname?
    #   Check if the member has the `CHANGE_NICKNAME` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_nicknames?
    #   Check if the member has the `MANAGE_NICKNAMES` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_guild?
    #   Check if the member has the `MANAGE_GUILD` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_view_audit_log?
    #   Check if the member has the `VIEW_AUDIT_LOG` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_view_guild_insights?
    #   Check if the member has the `VIEW_GUILD_INSIGHTS` permission.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_create_instant_invite?(channel = nil)
    #   Check if the member has the `CREATE_INSTANT_INVITE` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_channels?(channel = nil)
    #   Check if the member has the `MANAGE_CHANNELS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_add_reactions?(channel = nil)
    #   Check if the member has the `ADD_REACTIONS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_priority_speaker?(channel = nil)
    #   Check if the member has the `PRIORITY_SPEAKER` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_stream?(channel = nil)
    #   Check if the member has the `STREAM` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_read_messages?(channel = nil)
    #   Check if the member has the `READ_MESSAGES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_send_messages?(channel = nil)
    #   Check if the member has the `SEND_MESSAGES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_send_tts_messages?(channel = nil)
    #   Check if the member has the `SEND_TTS_MESSAGES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_messages?(channel = nil)
    #   Check if the member has the `MANAGE_MESSAGES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_embed_links?(channel = nil)
    #   Check if the member has the `EMBED_LINKS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_attach_files?(channel = nil)
    #   Check if the member has the `ATTACH_FILES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_read_message_history?(channel = nil)
    #   Check if the member has the `READ_MESSAGE_HISTORY` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_mention_everyone?(channel = nil)
    #   Check if the member has the `MENTION_EVERYONE` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_external_emojis?(channel = nil)
    #   Check if the member has the `USE_EXTERNAL_EMOJIS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_connect?(channel = nil)
    #   Check if the member has the `CONNECT` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_speak?(channel = nil)
    #   Check if the member has the `SPEAK` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_mute_members?(channel = nil)
    #   Check if the member has the `MUTE_MEMBERS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_deafen_members?(channel = nil)
    #   Check if the member has the `DEAFEN_MEMBERS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_move_members?(channel = nil)
    #   Check if the member has the `MOVE_MEMBERS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_voice_activity?(channel = nil)
    #   Check if the member has the `USE_VOICE_ACTIVITY` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_roles?(channel = nil)
    #   Check if the member has the `MANAGE_ROLES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_webhooks?(channel = nil)
    #   Check if the member has the `MANAGE_WEBHOOKS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_expressions?(channel = nil)
    #   Check if the member has the `MANAGE_EXPRESSIONS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_application_commands?(channel = nil)
    #   Check if the member has the `USE_APPLICATION_COMMANDS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_request_to_speak?(channel = nil)
    #   Check if the member has the `REQUEST_TO_SPEAK` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_scheduled_events?(channel = nil)
    #   Check if the member has the `MANAGE_SCHEDULED_EVENTS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_manage_threads?(channel = nil)
    #   Check if the member has the `MANAGE_THREADS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_create_public_threads?(channel = nil)
    #   Check if the member has the `CREATE_PUBLIC_THREADS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_create_private_threads?(channel = nil)
    #   Check if the member has the `CREATE_PRIVATE_THREADS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_external_stickers?(channel = nil)
    #   Check if the member has the `USE_EXTERNAL_STICKERS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_send_messages_in_threads?(channel = nil)
    #   Check if the member has the `SEND_MESSAGES_IN_THREADS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_embedded_activities?(channel = nil)
    #   Check if the member has the `USE_EMBEDDED_ACTIVITIES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_moderate_members?(channel = nil)
    #   Check if the member has the `MODERATE_MEMBERS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_view_monetization_analytics?(channel = nil)
    #   Check if the member has the `VIEW_MONETIZATION_ANALYTICS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_soundboard?(channel = nil)
    #   Check if the member has the `USE_SOUNDBOARD` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_create_expressions?(channel = nil)
    #   Check if the member has the `CREATE_EXPRESSIONS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_create_scheduled_events?(channel = nil)
    #   Check if the member has the `CREATE_SCHEDULED_EVENTS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_external_sounds?(channel = nil)
    #   Check if the member has the `USE_EXTERNAL_SOUNDS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_send_voice_messages?(channel = nil)
    #   Check if the member has the `SEND_VOICE_MESSAGES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_set_voice_channel_status?(channel = nil)
    #   Check if the member has the `SET_VOICE_CHANNEL_STATUS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_send_polls?(channel = nil)
    #   Check if the member has the `SEND_POLLS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_use_external_apps?(channel = nil)
    #   Check if the member has the `USE_EXTERNAL_APPS` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_pin_messages?(channel = nil)
    #   Check if the member has the `PIN_MESSAGES` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    #
    # @!method can_bypass_slowmode?(channel = nil)
    #   Check if the member has the `BYPASS_SLOWMODE` permission.
    #   @param channel [Channel, Integer, String, nil] The channel where the permission should be checked.
    #   @return [true, false] whether or not the member can perform the action.
    Discordrb::Permissions::MASKS.each_key do |flag|
      define_method("can_#{flag}?") do |channel = nil|
        permission?(flag, channel)
      end
    end

    alias :can_administrate? :can_administrator?

    private

    # @!visibility private
    def compute_overwrites(base, channel)
      # Threads inherit the permissions of their parent.
      channel = channel.parent if channel.thread?

      if (everyone = channel.overwrite(@guild_id))
        base &= ~everyone.denied.bits
        base |= everyone.allowed.bits
      end

      deny = 0
      allow = 0

      roles.each do |role|
        next unless (found = channel.overwrite(role.id))

        deny |= found.denied.bits
        allow |= found.allowed.bits
      end

      base &= ~deny
      base |= allow

      if (member_overwrite = channel.overwrite(@user.id))
        base &= ~member_overwrite.denied.bits
        base |= member_overwrite.allowed.bits
      end

      hash = Permissions::IMPLICIT
      connect = Permissions::MASKS[:connect]
      view = Permissions::MASKS[:read_messages]
      send = Permissions::MASKS[:send_messages]
      obfuscated = channel&.obfuscated? && @user.current_bot?

      if channel.text? || channel.announcement? || channel.forum? || channel.media?
        (base &= ~hash[:text]) if base.nobits?(view) || obfuscated
        (base &= ~hash[:send_messages]) if base.nobits?(send)
      elsif channel.voice?
        (base &= ~hash[:voice]) if base.nobits?(connect) || base.nobits?(view) || obfuscated
        (base &= ~hash[:send_messages]) if base.nobits?(send)
      elsif channel.stage?
        (base &= ~hash[:stage]) if base.nobits?(connect) || base.nobits?(view) || obfuscated
        (base &= ~hash[:send_messages]) if base.nobits?(send)
      end

      base
    end
  end
end
