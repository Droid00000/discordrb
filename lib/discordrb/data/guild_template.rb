# frozen_string_literal: true

module Discordrb
  # A snapshot of a guild.
  class GuildTemplate
    # @return [String] the code of the template.
    attr_reader :code

    # @return [String] the name of the template.
    attr_reader :name

    # @return [User] the user who created the template.
    attr_reader :creator

    # @return [Integer] the ID of the guild the template is for.
    attr_reader :guild_id

    # @return [Time] the time at when the source guild was last synced.
    attr_reader :synced_at

    # @return [Integer] the amount of times the template has been used.
    attr_reader :usage_count

    # @return [String, nil] the optional description of the guild template.
    attr_reader :description

    # @return [Time] the time at when the guild template was initially created.
    attr_reader :creation_time

    # @return [SourceGuild] the snapshot of the guild object the template is for.
    attr_reader :guild_snapshot

    alias_method :to_s, :code

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @code = data[:code]
      @guild_id = data[:source_guild_id].to_i
      @creator = bot.ensure_user(data[:creator])
      @creation_time = Time.iso8601(data[:created_at])
      update_data(data)
    end

    # Get the identity hash of the template.
    # @return [Integer] The hash of the template.
    def hash
      @code.hash
    end

    # Check if the guild template has been synced.
    # @return [true, false] Whether or not the guild template
    #   doesn't have any unsynced changes with the source guild.
    def synced?
      @unsynced == false
    end

    # Get a link to the guild template.
    # @return [String] A URL to the guild template.
    def link
      "https://discord.new/#{@code}"
    end

    alias_method :url, :link

    # Sync the guild template to match the source guild.
    # @return [nil]
    def sync
      update_data(@bot.http.sync_guild_template(@guild_id, @code))
      nil
    end

    # Delete the guild template. This action is irreversible and cannot be undone.
    # @return [nil]
    def delete
      update_data(@bot.http.delete_guild_template(@guild_id, @code))
      nil
    end

    # Modify the properties of the guild template.
    # @param name [String] The new 1-100 character name of the guild template.
    # @param description [String, nil] The new 1-120 character description of the guild template.
    # @return [nil]
    def modify(name: :undef, description: :undef)
      update_data(@bot.http.modify_guild_template(@guild_id, @code, name:, description:))
      nil
    end

    # Comparison based off of guild ID and code.
    # @param other [ServerTemplate, Object] The object to compare against.
    # @return [true, false] Whether or not the other object is equal to this guild template.
    def ==(other)
      other.is_a?(GuildTemplate) ? (@guild_id == other.guild_id && @code == other.code) : false
    end

    alias_method :eql?, :==

    # @!visibility private
    def inspect
      "<GuildTemplate code=\"#{@code}\" guild_id=#{@guild_id} name=\"#{@name}\">"
    end

    private

    # @!visibility private
    def update_data(new_data)
      @name = new_data[:name]
      @description = new_data[:description]
      @usage_count = new_data[:usage_count]
      @unsynced = new_data[:is_dirty] || false
      @synced_at = Time.iso8601(new_data[:updated_at])
      @guild_snapshot = SourceGuild.new(new_data[:serialized_source_guild], @bot)
    end

    # The snapshot of a template's guild.
    class SourceGuild
      include GuildAttributes

      # @return [Array<Role>] an array of all the roles created in the guild.
      attr_reader :roles

      # @return [String] the preferred locale of the guild, used in the discovery tab.
      attr_reader :locale

      # @return [Array<Channel>] an array of all the channels (text and voice) in the guild.
      attr_reader :channels

      # @return [String, nil] the description of the source guild that's shown in the discovery tab.
      attr_reader :description

      # @return [Integer] the amount of time after which a voice user gets moved into the AFK channel.
      attr_reader :afk_timeout

      # @return [Integer] the flags that have been set for the guild's system channel combined as a bitfield.
      attr_reader :system_channel_flags

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @name = data[:name]
        @roles = data[:roles].map do |role|
          role[:colors] ||= { primary_color: role[:color] }
          Role.new(role, nil, @bot)
        end
        @locale = data[:preferred_locale]
        @channels = data[:channels].map { |channel| Channel.new(channel, @bot) }
        @description = data[:description]
        @afk_timeout = data[:afk_timeout]
        @afk_channel_id = data[:afk_channel_id]&.to_i
        @verification_level = data[:verification_level]
        @system_channel_id = data[:system_channel_id]&.to_i
        @system_channel_flags = data[:system_channel_flags] || 0
        @explicit_content_filter = data[:explicit_content_filter]
        @notification_level = data[:default_message_notifications]
      end

      # Get the verification level of the source guild.
      # @return [Symbol] the verification level of the source guild.
      def verification_level
        Discordrb::Guild::VERIFICATION_LEVELS.key(@verification_level)
      end

      # Get the explicit content filter level of the source guild.
      # @return [Symbol] the explicit content filter level of the guild.
      def explicit_content_filter
        Discordrb::Guild::FILTER_LEVELS.key(@explicit_content_filter)
      end

      # Get the default message notification setting of the source guild.
      # @return [Symbol] the default message notifications setting of the source guild.
      def notification_level
        Discordrb::Guild::NOTIFICATION_LEVELS.key(@notification_level)
      end

      # Get the AFK voice channel of the source guild.
      # @return [Channel, nil] the AFK voice channel of the source guild, or `nil` if none is set.
      def afk_channel
        @channels.find { |channel| channel.id == @afk_channel_id } if @afk_channel_id
      end

      # Get the system channel of the source guild.
      # @return [Channel, nil] the system channel used for automatic welcome messages for the source
      #   guild, or `nil` if none is set.
      def system_channel
        @channels.find { |channel| channel.id == @system_channel_id } if @system_channel_id
      end
    end
  end
end
