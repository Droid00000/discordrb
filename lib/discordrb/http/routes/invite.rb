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
    def update_invite_target_users(invite_code, target_users_file)
      body = {
        target_users_file: Faraday::Multipart::FilePart.new(
          target_users_file,
          'text/csv',
          'target_users_file.csv'
        )
      }

      request Route[:PUT, "/invites/#{invite_code}/target-users"],
              body: body
    end

    # @see https://docs.discord.com/developers/resources/invite#get-target-users-job-status
    def get_invite_target_users_job_status(invite_code, **params)
      request Route[:GET, "/invites/#{invite_code}/target-users/job-status"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/invite#bulk-add-invite-target-users
    def bulk_add_invite_target_users(invite_code, **body)
      request Route[:POST, "/invites/#{invite_code}/target-users/bulk-add"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/invite#bulk-remove-invite-target-users
    def bulk_remove_invite_target_users(invite_code, **body)
      request Route[:POST, "/invites/#{invite_code}/target-users/bulk-delete"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/invite#add-invite-target-user
    def add_invite_target_user(invite_code, user_id, **body)
      request Route[:PUT, "/invites/#{invite_code}/target-users/#{user_id}"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/invite#remove-invite-target-user
    def remove_invite_target_user(invite_code, user_id, **body)
      request Route[:DELETE, "/invites/#{invite_code}/target-users/#{user_id}"],
              body: filter_undef(body)
    end
  end
end
