# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/channels
  module ChannelEndpoints
    # @see https://docs.discord.com/developers/resources/channel#get-channel
    def get_channel(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#modify-channel
    def modify_channel(channel_id, reason: :undef, **body)
      request Route[:PATCH, "/channels/#{channel_id}", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#set-voice-channel-status
    def set_voice_channel_status(channel_id, reason: :undef, **body)
      request Route[:PUT, "/channels/#{channel_id}/voice-status", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#delete-channel
    def delete_channel(channel_id, reason: :undef, **params)
      request Route[:DELETE, "/channels/#{channel_id}", channel_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#edit-channel-permissions
    def modify_channel_permissions(channel_id, overwrite_id, reason: :undef, **body)
      request Route[:PUT, "/channels/#{channel_id}/permissions/#{overwrite_id}", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#get-channel-invites
    def list_channel_invites(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/invites", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#create-channel-invite
    def create_channel_invite(channel_id, target_users_file: :undef, reason: :undef, **body)
      filter_undef(body)

      if target_users_file != :undef
        body = {
          payload_json: JSON.dump(body),
          target_users_file: Faraday::Multipart::FilePart.new(
            target_users_file,
            'text/csv',
            'target_users_file.csv'
          )
        }
      end

      request Route[:POST, "/channels/#{channel_id}/invites", channel_id],
              body: body, reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#delete-channel-permissions
    def delete_channel_permissions(channel_id, overwrite_id, reason: :undef, **params)
      request Route[:DELETE, "/channels/#{channel_id}/permissions/#{overwrite_id}", channel_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#follow-announcement-channel
    def follow_announcement_channel(channel_id, reason: :undef, **body)
      request Route[:POST, "/channels/#{channel_id}/followers", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#trigger-typing-indicator
    def trigger_typing_indicator(channel_id, **body)
      request Route[:POST, "/channels/#{channel_id}/typing", channel_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/channel#start-thread-from-message
    def start_thread_from_message(channel_id, message_id, reason: :undef, **body)
      request Route[:POST, "/channels/#{channel_id}/messages/#{message_id}/threads", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#start-thread-without-message
    def start_thread_without_message(channel_id, reason: :undef, **body)
      request Route[:POST, "/channels/#{channel_id}/threads", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/channel#join-thread
    def join_thread(channel_id, **body)
      request Route[:PUT, "/channels/#{channel_id}/thread-members/@me", channel_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/channel#add-thread-member
    def add_thread_member(channel_id, user_id, **body)
      request Route[:PUT, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/channel#leave-thread
    def leave_thread(channel_id, **params)
      request Route[:DELETE, "/channels/#{channel_id}/thread-members/@me", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#remove-thread-member
    def remove_thread_member(channel_id, user_id, **params)
      request Route[:DELETE, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#get-thread-member
    def get_thread_member(channel_id, user_id, **params)
      request Route[:GET, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#list-thread-members
    def list_thread_members(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/thread-members", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#list-public-archived-threads
    def list_public_archived_threads(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/threads/archived/public", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#list-private-archived-threads
    def list_private_archived_threads(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/threads/archived/private", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/channel#list-joined-private-archived-threads
    def list_joined_private_archived_threads(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/users/@me/threads/archived/private", channel_id],
              params: filter_undef(params)
    end
  end
end
