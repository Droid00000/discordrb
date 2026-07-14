# frozen_string_literal: true

module Discordrb
  # A Role that can be granted to a member.
  class Role
    include Snowflake

    # @!visibility private
    PREDICATES = %i[
      managed
      hoisted
      mentionable
      connections
      premium_subscriber
      available_for_purchase
    ].freeze

    # @return [String] the name of the role.
    attr_reader :name

    # @return [String, nil] the CDN hash for the role's custom icon.
    attr_reader :icon

    # @return [Integer] the flags for the role.
    attr_reader :flags

    # @return [ColourRGB] the primary color of the role.
    attr_reader :color

    # @return [Integer] the ID of the guild that the role originates from.
    attr_reader :guild_id

    # @return [Integer] the sorting position of the role. Not always unique.
    attr_reader :position

    # @return [Permissions] the permissions granted to members who have the role.
    attr_reader :permissions

    # @return [String, nil] the unicode emoji for the role's icon.
    attr_reader :unicode_emoji

    # @return [ColourRGB, nil] the third color for the role's gradident.
    attr_reader :tertiary_color

    # @return [ColourRGB, nil] the second color for the role's gradident.
    attr_reader :secondary_color

    # @return [Integer, nil] the ID of the bot the auto-generated role is for.
    attr_reader :bot_id

    # @return [Integer, nil] the ID of the integration that the role belongs to.
    attr_reader :integration_id

    # @return [Integer, nil] the id ID of the role’s subscription sku and listing.
    attr_reader :subscription_listing_id

    alias_method :colour, :color
    alias_method :tertiary_colour, :tertiary_color
    alias_method :secondary_colour, :secondary_color

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @id = data[:id].to_i
      @guild_id = guild&.id || data[:guild_id]&.to_i
      update_data(data)
    end

    # @!attribute [r] managed?
    #   @return [true, false] whether the role is managed by an integration, such as the Twitch integration.
    # @!attribute [r] hoisted?
    #   @return [true, false] whether members with the role should be shown seperately in the members list.
    # @!attribute [r] mentionable?
    #   @return [true, false] whether the role can be mentioned by anyone.
    # @!attribute [r] connections?
    #   @return [true, false] whether the role is a linked role for the guild.
    # @!attribute premium_subscriber?
    #   @return [true, false] whether the role is the auto-generated booster role for the guild.
    # @!attribute available_for_purchase?
    #   @return [true, false] whether the role is available for purchase in the guild's creator store page.
    PREDICATES.each do |name|
      define_method("#{name}?") { instance_variable_get("@#{name}") }
    end

    # Get a string that will mention the role.
    # @return [String] A string that will mention the role.
    def mention
      "<@&#{@id}>"
    end

    # Get the guild that the role is associated with.
    # @return [Guild, nil] The guild that the role belongs to.
    def guild
      @guild ||= (@bot.guild(@guild_id) if @guild_id)
    end

    # Get the guild members that currenrly have the role.
    # @return [Array<Member>] The members who currently have the role.
    def members
      guild.members.select { |member| member.role?(@id) }
    end

    # Modify the properties of the role.
    # @param name [String, nil] The new name of the role; between 1-100 characters.
    # @param unicode_emoji [String, nil] The standard unicode emoji to set for the role's icon.
    # @param display_icon [File, String, Emoji, nil] The custom icon or unicode emoji to set for the role.
    # @param permissions [Permissions, Integer, String, nil] The permissions to set for the role.
    # @param icon [File, #read, nil] The custom icon to set for the role. Must be a file-like object.
    # @param hoisted [true, false, nil] Whether or not the role should be shown separately in the member's list.
    # @param mentionable [true, false, nil] Whether or not any guild member can mention the role in messages.
    # @param colour [Integer, ColourRGB, nil] The primary colour to set for the role.
    # @param tertiary_colour [Integer, ColourRGB, nil] The tertiary colour to set for the role.
    # @param secondary_colour [Integer, ColourRGB, nil] The secondary colour to set for the role.
    # @param reason [String, nil] the reason to show in the guild's audit log for updating the role.
    # @yieldparam builder [Permissions] An optional permissions builder. Ignored when `permissions:` is passed.
    # @note The American spelling can be used instead of the British spelling for all of the colour parameters.
    # @return [nil]
    def modify(
      name: :undef, hoisted: :undef, mentionable: :undef, icon: :undef,
      unicode_emoji: :undef, display_icon: :undef, colour: :undef, color: :undef,
      secondary_colour: :undef, secondary_color: :undef, tertiary_colour: :undef,
      tertiary_color: :undef, permissions: :undef, reason: nil
    )
      if display_icon != :undef
        if icon != :undef || unicode_emoji != :undef
          raise ArgumentError, "'display_icon' is mutually exclusive with 'icon' and 'unicode_emoji'"
        end

        if display_icon.nil?
          icon = nil
          unicode_emoji = nil
        elsif display_icon.is_a?(String)
          icon = nil
          unicode_emoji = display_icon
        elsif display_icon.respond_to?(:read)
          icon = display_icon
          unicode_emoji = nil
        elsif display_icon.is_a?(Discordrb::Emoji)
          if display_icon.id
            request = Faraday.get(display_icon.url(format: 'png', size: 4096))
            icon = request.success? ? StringIO.new(request.body, 'rb') : :undef
            unicode_emoji = nil if request.success?
          elsif display_icon.name
            icon = nil
            unicode_emoji = icon.name
          end
        end
      end

      if block_given? && permissions == :undef
        yield((builder = Permissions.new(@permissions.bits)))
        permissions = builder.bits
      end

      permissions = if permissions.is_a?(Array)
                      Permissions.bits(permissions)
                    elsif permissions.respond_to?(:bits)
                      permissions.bits
                    else
                      permissions
                    end

      data = {
        name: name,
        mentionable: mentionable,
        hoist: hoisted,
        unicode_emoji: unicode_emoji,
        icon: icon.respond_to?(:read) ? Discordrb.encode64(icon) : icon,
        permissions: permissions == :undef ? permissions : permissions&.to_s
      }

      color = (colour == :undef ? color : colour)
      tertiary = (tertiary_colour == :undef ? tertiary_color : tertiary_colour)
      secondary = (secondary_colour == :undef ? secondary_color : secondary_colour)

      if color != :undef || secondary != :undef || tertiary != :undef
        data[:colors] = {
          primary_color: (color == :undef ? @color : color)&.to_i,
          tertiary_color: (tertiary == :undef ? @tertiary_color : tertiary)&.to_i,
          secondary_color: (secondary == :undef ? @secondary_color : secondary)&.to_i
        }
      end

      update_data(@bot.http.modify_guild_role(@guild_id, @id, **data, reason: reason))
      nil
    end

    # Move the position of this role in the roles list.
    # @example This will move the role 2 places above the `@everyone` role.
    #   role.move(bottom: true, offset: 2)
    # @example This will move the role above the `@muted` role.
    #   role.move(above: 257017090932867072)
    # @example This will move the role 3 spots below the `@moderator` role.
    #   role.move(below: 254077236989132800, offset: -3)
    # @param bottom [true, false, nil] Whether to move the roles to the bottom of the role list.
    # @param above [Integer, String, Role, nil] The role that this role should be moved above.
    # @param below [Integer, String, Role, nil] The role that this role should be moved below.
    # @param offset [Integer, nil] The number of roles to offset the new position by. A positive number will
    #   move the role above, and a negative number will move the role below. This parameter is relative and
    #   calculated after the `bottom`, `above`, and `below` parameters.
    # @param reason [String, nil] The audit log reason to show for moving the role.
    # @return [Integer] The new position of the role.
    def move(bottom: nil, above: nil, below: nil, offset: 0, reason: nil)
      if [bottom, above, below].count(&:itself) > 1
        raise ArgumentError, "'bottom', 'above', and 'below' are mutually exclusive"
      end

      if (above || below) && !(target = guild.role(above || below))
        raise ArgumentError, "The given 'above' or 'below' options are not valid"
      end

      if (below && target&.id == @guild_id) || (@id == target&.id)
        raise ArgumentError, 'The target role that was provded is not valid'
      end

      roles = guild.roles(sorted: true)

      # Ensure we remove the current role.
      myself = roles.rindex(@id).tap { |index| roles.delete_at(index) }

      index = if bottom
                1
              elsif below
                roles.rindex(target)
              elsif above
                roles.rindex(target) + 1
              else
                myself
              end

      roles.insert([index + (offset || 0), 1].max, self)

      roles = roles.map.with_index do |role, new_position|
        { id: role.resolve_id, position: new_position }
      end

      guild.update_role_positions(roles, reason: reason)
      @position
    end

    # @!group Comparison Operators

    # Compare the role against another role based on its position.
    # @param other [Role] The role to compare the current role against.
    # @return [0, -1, 1, nil] An integer representing the ordering of the
    #   roles, or `nil` if the other entity is not able to be compared to the role.
    def <=>(other)
      return unless other.is_a?(Role) && @guild_id == other.guild_id

      if @id == other.id
        0
      elsif @position == other.position
        other.id <=> @id
      else
        @position <=> other.position
      end
    end

    # Check if the role is less than another role in the hierarchy.
    # @param other [Role] The other role that you want to compare to this one.
    # @return [true, false] Whether or not the role is less than the other role in the hierarchy.
    def <(other)
      self.<=>(other) < 0
    end

    # Check if the role is greater than another role in the hierarchy.
    # @param other [Role] The other role that you want to compare to this one.
    # @return [true, false] Whether or not the role is greater than the other role in the hierarchy.
    def >(other)
      self.<=>(other) > 0
    end

    # Check if the role is less than or equal to another role in the hierarchy.
    # @param other [Role] The other role that you want to compare against this one.
    # @return [true, false] Whether or not the role is less than or equal to the other role in the hierarchy.
    def <=(other)
      self.<=>(other) <= 0
    end

    # Check if the role is greater than or equal to another role in the hierarchy.
    # @param other [Role] The other role that you want to compare against this one.
    # @return [true, false] Whether or not the role is greater than or equal to the other role in the hierarchy.
    def >=(other)
      self.<=>(other) >= 0
    end

    # @!endgroup Comparison Operators

    # Get the icon that the role will display in the client.
    # @return [String, nil] The icon URL, the unicode emoji, or nil if the role doesn't have an icon.
    # @note A role can have a unicode emoji and an icon, but only the custom icon will be displayed in the client.
    def display_icon
      icon_url || unicode_emoji
    end

    # Utility method to get a role's custom icon URL.
    # @param format [String] The extension to return the URL in. Can be one of `webp`, `jpg`, or `png`.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the role's icon, or `nil` if the role doesn't have a custom icon set.
    def icon_url(format: 'webp', size: nil)
      Assets[:role_icon, @id, @icon, format, size:] if @icon
    end

    # Deletes the role. This cannot be undone without recreating the role.
    # @param reason [String] The reason to show in the guild's audit log for deleting the role.
    # @return [nil]
    def delete(reason: nil)
      @bot.http.delete_guild_role(@guild_id, @id, reason: reason)
      @guild&.delete_role(@id)
      nil
    end

    # @!visibility private
    def inspect
      "<Role id=#{@id} guild_id=#{@guild_id} name=\"#{@name}\">"
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data[:name]
      @hoisted = new_data[:hoist]
      @icon = new_data[:icon]
      @unicode_emoji = new_data[:unicode_emoji]
      @position = new_data[:position]
      @mentionable = new_data[:mentionable]
      @flags = new_data[:flags] || 0
      colors = new_data[:colors]
      @managed = new_data[:managed]
      @color = ColourRGB.new(colors[:primary_color])
      @permissions = Permissions.new(new_data[:permissions].to_i)
      @tertiary_color = colors[:tertiary_color] ? ColourRGB.new(colors[:tertiary_color]) : nil
      @secondary_color = colors[:secondary_color] ? ColourRGB.new(colors[:secondary_color]) : nil

      tags = new_data[:tags]
      @bot_id = tags&.[](:bot_id)&.to_i
      @integration_id = tags&.[](:integration_id)&.to_i
      @premium_subscriber = tags&.key?(:premium_subscriber) || false
      @subscription_listing_id = tags&.[](:subscription_listing_id)&.to_i
      @available_for_purchase = tags&.key?(:available_for_purchase) || false
      @connections = tags&.key?(:guild_connections) || false
    end
  end
end
