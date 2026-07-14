# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/sticker
  module StickerEndpoints
    # @see https://docs.discord.com/developers/resources/stage-instance#get-sticker
    def get_sticker(sticker_id, **params)
      request Route[:GET, "/stickers/#{sticker_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/sticker#list-sticker-packs
    def list_sticker_packs(**params)
      request Route[:GET, '/sticker-packs'],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/sticker#get-sticker-pack
    def get_sticker_pack(sticker_pack_id, **params)
      request Route[:GET, "/sticker-packs/#{sticker_pack_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/sticker#list-guild-stickers
    def list_guild_stickers(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/stickers", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/sticker#get-guild-sticker
    def get_guild_sticker(guild_id, sticker_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/stickers/#{sticker_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/sticker#create-guild-sticker
    def create_guild_sticker(guild_id, file:, reason: :undef, **body)
      body = {
        payload_json: JSON.dump(body),
        file: Faraday::Multipart::FilePart.new(
          file,
          Discordrb.sniff_mime_type(file)
        )
      }

      request Route[:POST, "/guilds/#{guild_id}/stickers", guild_id],
              body: body, reason: reason
    end

    # @see https://docs.discord.com/developers/resources/sticker#modify-guild-sticker
    def modify_guild_sticker(guild_id, sticker_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/stickers/#{sticker_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/sticker#delete-guild-sticker
    def delete_guild_sticker(guild_id, sticker_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/stickers/#{sticker_id}", guild_id],
              params: filter_undef(params), reason: reason
    end
  end
end
