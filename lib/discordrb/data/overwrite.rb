# frozen_string_literal: true

module Discordrb
  # A permission overwrite for a channel.
  class Overwrite
    # Mapping of types.
    TYPES = {
      role: 0,
      member: 1
    }.freeze

    # @return [Integer] the target ID of the overwrite.
    attr_reader :id

    # @return [Symbol] the target type of the overwrite.
    attr_reader :type

    # @return [Permissions] the denied permissions for the
    #   overwrite (red x-mark).
    attr_reader :denied

    # @return [Permissions] the allowed permissions for the
    #   overwrite (green checkmark).
    attr_reader :allowed

    # @!visibility private
    alias_method :resolve_id, :id

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @channel = channel
      @id = data[:id].to_i
      @type = TYPES.key(data[:type])
      @denied = Permissions.new(data[:deny].to_i)
      @allowed = Permissions.new(data[:allow].to_i)
    end

    # Get the role that the overwrite targets.
    # @return [Role, nil] The role that the overwrite targets.
    def role
      role? ? target : nil
    end

    # Get the member that the overwrite targets.
    # @return [Member, nil] The member that the overwrite targets.
    def member
      member? ? target : nil
    end

    # Get the entity that the overwrite targets.
    # @return [Role, Member, nil] The entity that the overwrite targets.
    def target
      guild = @channel.guild

      role? ? guild.role(@id) : guild.member(@id)
    end

    # Check if two overwrite objects are the same.
    # @param other [Overwrite] The overwrite to compare against.
    # @return [true, false] Whether or not the overwrites are the same.
    def ==(other)
      return false unless other.is_a?(Overwrite)

      @id == other.id && @type == other.type &&
        @denied == other.denied && @allowed == other.allowed
    end

    alias_method :eql?, :==

    # @!method role?
    #   @return [true, false] whether or not the overwrite is for a role.
    # @!method member?
    #   @return [true, false] whether or not the overwrite is for a member.
    TYPES.each_key do |name|
      define_method("#{name}?") { @type == name }
    end

    # @!visibility private
    def to_h
      {
        id: @id,
        type: TYPES[@type],
        deny: @denied.bits.to_s,
        allow: @allowed.bits.to_s
      }
    end

    # @!visibility private
    def inspect
      "<Overwrite id=#{@id} allowed=#{@allowed.bits} denied=#{@denied.bits}>"
    end

    # @!visibility private
    def self.build_hash(role: nil, user: nil, member: nil, **permissions)
      if [role, user, member].count(&:itself) != 1
        raise ArgumentError, "'role', 'user', and 'member' are mutually exclusive"
      end

      denied = 0
      allowed = 0

      permissions.each do |key, value|
        unless (computed = Permissions::MASKS[key&.to_sym])
          raise ArgumentError, "Invalid permission value: '#{key}'"
        end

        if value == false
          denied |= computed
        elsif value == true
          allowed |= computed
        else
          raise TypeError, "Only 'true' and 'false' are valid values"
        end
      end

      {
        deny: denied.to_s,
        allow: allowed.to_s,
        id: (user || member)&.resolve_id || role.resolve_id,
        type: member || user ? Overwrite::TYPES[:member] : Overwrite::TYPES[:role]
      }
    end
  end
end
