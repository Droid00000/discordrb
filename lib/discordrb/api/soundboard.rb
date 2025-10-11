# frozen_string_literal: true

# API calls for Soundboard sounds.
module Discordrb::API::Soundboard
  module_function

  # Play a soundboard sound in a voice channel.
  # https://discord.com/developers/docs/resources/soundboard#send-soundboard-sound
  def send_soundboard_sound(token, sound_id, channel_id, source_guild_id = nil)
    Discordrb::API.request(
      :channels_cid_send_soundboard_sound,
      channel_id,
      :post,
      "#{Discordrb::API.api_base}/channels/#{channel_id}/send-soundboard-sound",
      { sound_id: sound_id, source_guild_id: source_guild_id }.compact.to_json,
      content_type: :json,
      Authorization: token
    )
  end

  # Get a list of the default soundboard sounds that can be used by anyone.
  # https://discord.com/developers/docs/resources/soundboard#list-default-soundboard-sounds
  def list_default_soundboard_sounds(token)
    Discordrb::API.request(
      :soundboard_default_sounds,
      nil,
      :get,
      "#{Discordrb::API.api_base}/soundboard-default-sounds",
      Authorization: token
    )
  end

  # Get a list of all of the custom soundboard sounds in a server.
  # https://discord.com/developers/docs/resources/soundboard#list-guild-soundboard-sounds
  def list_soundboard_sounds(token, server_id)
    Discordrb::API.request(
      :guilds_sid_soundboard_sounds,
      server_id,
      :get,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/soundboard-sounds",
      Authorization: token
    )
  end

  # Get a custom single soundboard sound in a server.
  # https://discord.com/developers/docs/resources/soundboard#get-guild-soundboard-sound
  def get_soundboard_sound(token, server_id, sound_id)
    Discordrb::API.request(
      :guilds_sid_soundboard_sounds_sid,
      server_id,
      :get,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/soundboard-sounds/#{sound_id}",
      Authorization: token
    )
  end

  # Create a custom soundboard sound in a server.
  # https://discord.com/developers/docs/resources/soundboard#create-guild-soundboard-sound
  def create_soundboard_sound(token, server_id, name:, sound:, volume: :undef, emoji_id: :undef, emoji_name: :undef, reason: nil)
    Discordrb::API.request(
      :guilds_sid_soundboard_sounds,
      server_id,
      :post,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/soundboard-sounds",
      { name:, sound:, volume:, emoji_id:, emoji_name: }.reject { |_, value| value == :undef }.to_json,
      content_type: :json,
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end

  # Update a custom soundboard sound in a server.
  # https://discord.com/developers/docs/resources/soundboard#modify-guild-soundboard-sound
  def update_soundboard_sound(token, server_id, sound_id, name: :undef, volume: :undef, emoji_id: :undef, emoji_name: :undef, reason: nil)
    Discordrb::API.request(
      :guilds_sid_soundboard_sounds_sid,
      server_id,
      :patch,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/soundboard-sounds/#{sound_id}",
      { name:, volume:, emoji_id:, emoji_name: }.reject { |_, value| value == :undef }.to_json,
      content_type: :json,
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end

  # Delete a custom soundboard sound in a server.
  # https://discord.com/developers/docs/resources/soundboard#delete-guild-soundboard-sound
  def delete_soundboard_sound(token, server_id, sound_id, reason: nil)
    Discordrb::API.request(
      :guilds_sid_soundboard_sounds_sid,
      server_id,
      :delete,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/soundboard-sounds/#{sound_id}",
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end
end
