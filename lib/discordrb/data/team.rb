# frozen_string_literal: true

module Discordrb
  # A group of users that can manage a group of applications.
  class Team
    include IDObject

    # A member that has been invited to a team.
    class Member
      # @return [Symbol] the role of this team member.
      attr_reader :role

      # @return [Team] the team this member is a part of.
      attr_reader :team

      # @return [Integer] the membership state of this team member.
      attr_reader :state

      # @return [Integer] the ID of the user this team member is for.
      attr_reader :user_id

      # @!visibility private
      def initialize(data, team, bot)
        @bot = bot
        @team = team
        @role = data['role'].to_sym
        @state = data['membership_state']
        @user_id = data['user']['id'].to_i
      end

      # Whether this team member has been invited to the team, but hasn't accepted the invite yet.
      # @return [true, false]
      def invited?
        @state == 1
      end

      # Whether this team member has been invited to the team, and if they have accepted the invite.
      # @return [true, false]
      def accepted?
        @state == 2
      end

      # Get the user associated with this team member.
      # @return [User]
      def user
        @bot.user(@user_id)
      end
    end

    # @return [String] the name of this team.
    attr_reader :name

    # @return [Member] the owner of this team.
    attr_reader :owner

    # @return [String, nil] the ID of this team's icon. Can be used to generate an icon URL.
    # @see #icon_url
    attr_reader :icon_id

    # @return [Array<Member>] the members that are a part of this team.
    attr_reader :members

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @name = data['name']
      @icon_id = data['icon']
      @members = data['members'].map { |member| Member.new(member, self, bot) }
      @owner = @members.find { |member| member.user_id == data['owner_user_id'].to_i }
    end

    # Utility method to get a team's icon URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
    # @return [String, nil] the URL to the icon image (nil if no image is set).
    def icon_url(format = 'webp')
      API.team_icon_url(@id, @icon_id, format) if @icon_id
    end
  end
end
