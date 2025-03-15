# frozen_string_literal: true

# API calls for stickers
module Discordrb::API::Sticker
  module_function

  # Return a single sticker object given the ID.
  # https://discord.com/developers/docs/resources/sticker#get-sticker
  def sticker(token, sticker_id)
    Discordrb::API.request(
      :stickers_sid,
      :sticker_id,
      :get,
      "#{Discordrb::API.api_base}/stickers/#{sticker_id}",
      Authorization: token
    )
  end

  # Get a sticker pack object given its ID.
  # https://discord.com/developers/docs/resources/sticker#get-sticker-pack
  def pack(token, pack_id)
    Discordrb::API.request(
      :stickers_sid,
      :sticker_id,
      :get,
      "#{Discordrb::API.api_base}/sticker-packs/#{pack_id}",
      Authorization: token
    )
  end

  # Add a custom sticker to a sticker.
  # https://discord.com/developers/docs/resources/sticker#create-guild-sticker
  def add_sticker(token, server_id, file, name, description, tags, reason = nil)
    Discordrb::API.request(
      :guilds_sid_stickers,
      :server_id,
      :post,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers",
      { name: name, description: description, tags: tags, file: file },
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end

  # Change a custom sticker's name, description, or tags.
  # https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
  def edit_sticker(token, server_id, sticker_id, name, description, tags, reason = nil)
    Discordrb::API.request(
      :guilds_sid_stickers_sid,
      server_id,
      :patch,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers/#{sticker_id}",
      { name: name, description: description, tags: tags }.to_json,
      Authorization: token,
      content_type: :json,
      'X-Audit-Log-Reason': reason
    )
  end

  # Deletes a custom sticker from a server.
  # https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
  def delete_sticker(token, server_id, sticker_id, reason = nil)
    Discordrb::API.request(
      :guilds_sid_stickers_sid,
      server_id,
      :delete,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers/#{sticker_id}",
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end
end
