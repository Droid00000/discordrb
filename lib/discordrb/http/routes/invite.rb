# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/invite
  module InviteEndpoints
    # @see https://docs.discord.com/developers/resources/invite#get-invite
    def get_invite(invite_code, **params)
      request Route[:GET, "/invites/#{invite_code}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/invite#delete-invite
    def delete_invite(invite_code, reason: :undef, **params)
      request Route[:DELETE, "/invites/#{invite_code}"],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/invite#get-target-users
    def get_invite_target_users(invite_code, **params)
      request Route[:GET, "/invites/#{invite_code}/target-users"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/invite#update-target-users
    def update_invite_target_users(invite_code, target_users)
      request Route[:PUT, "/invites/#{invite_code}/target-users"],
              body: target_users
    end

    # @see https://docs.discord.com/developers/resources/invite#get-target-users-job-status
    def get_invite_target_users_job_status(invite_code, **params)
      request Route[:GET, "/invites/#{invite_code}/target-users/job-status"],
              params: filter_undef(params)
    end
  end
end
