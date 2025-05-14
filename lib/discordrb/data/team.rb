# frozen_string_literal: true

module Discordrb
  # A group of developers that can manage an application.
  class Team
    include IDObject
    # A member of a team.
    class Member
      # @return [Team] The team this member is a part of.
      attr_reader :team

      # @return [Symbol] The current role of the team member.
      attr_reader :role

      # @return [Integer] The ID of the user this member is for.
      attr_reader :user_id

      # @!visibility private
      def initialize(data, team, bot)
        @bot = bot
        @team = team
        @role = data['role'].to_sym
        @user_id = data['user']['id'].to_i
        @membership_state = data['membership_state']
      end

      # @return [User] The user this team member is for.
      def user
        @bot.user(@user_id)
      end

      # @return [Boolean] If this member's been invited to the team, but hasn't accepted yet.
      def invited?
        @membership_state == 1
      end

      # @return [Boolean] If this member's been invited to the team, and has accepted the invite.
      def accepted?
        @membership_state == 2
      end
    end

    # @return [String] The name of the team.
    attr_reader :name

    # @return [Team::Member] The member that owns this team.
    attr_reader :owner

    # @return [Array<Team::Member>] Array of members on this team.
    attr_reader :members

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @icon_id = data['icon']
      @members = data['members'].map { |member| Member.new(member, self, bot) }
      @owner = @members.find { |member| member.user_id == data['owner_user_id'].to_i }
    end

    # Utility method to get an team's icon URL.
    # @return [String, nil] The URL of the icon's image (nil if no image is set.)
    def icon_url
      @icon_id ? API.team_icon_url(@id, @icon) : nil
    end
  end
end
