# frozen_string_literal: true

module Discordrb
  # A helper class for CDN assets.
  class Assets
    # The base CDN URL.
    BASE = 'https://cdn.discordapp.com'

    # Mapping of CDN endpoints.
    ENDPOINTS = {
      custom_emoji: "#{BASE}/emojis/%s.%s",
      guild_icon: "#{BASE}/icons/%s/%s.%s",
      guild_splash: "#{BASE}/splashes/%s/%s.%s",
      guild_discovery_splash: "#{BASE}/discovery-splashes/%s/%s.%s",
      guild_banner: "#{BASE}/banners/%s/%s.%s",
      guild_widget: "#{BASE}/guilds/%s/widget.png",
      user_banner: "#{BASE}/banners/%s/%s.%s",
      default_user_avatar: "#{BASE}/embed/avatars/%s.%s",
      user_avatar: "#{BASE}/avatars/%s/%s.%s",
      guild_member_avatar: "#{BASE}/guilds/%s/users/%s/avatars/%s.%s",
      avatar_decoration: "#{BASE}/avatar-decoration-presets/%s.%s",
      application_icon: "#{BASE}/app-icons/%s/%s.%s",
      application_cover: "#{BASE}/app-icons/%s/%s.%s",
      application_asset: "#{BASE}/app-assets/%s/%s.%s",
      achivement_icon: "#{BASE}/app-assets/%s/achievements/%s/icons/%s.%s",
      store_page_asset: "#{BASE}/app-assets/%s/store/%s.%s",
      sticker_pack_banner: "#{BASE}/app-assets/710982414301790216/store/%s.%s",
      team_icon: "#{BASE}/team-icons/%s/%s.%s",
      sticker: "#{BASE}/stickers/%s.%s",
      gif_sticker: 'https://media.discordapp.net/stickers/%s.%s',
      role_icon: "#{BASE}/role-icons/%s/%s.%s",
      guild_scheduled_event_cover: "#{BASE}/guild-events/%s/%s.%s",
      guild_member_banner: "#{BASE}/guilds/%s/users/%s/banners/%s.%s",
      guild_tag_badge: "#{BASE}/guild-tag-badges/%s/%s.%s",
      nameplate_asset: "#{BASE}/assets/collectibles/%sasset.%s",
      static_nameplate_asset: "#{BASE}/assets/collectibles/%sstatic.%s",
      soundboard_sound: "#{BASE}/soundboard-sounds/%s"
    }.freeze

    # Create a new asset URL.
    # @example Generate a URL for a custom emoji.
    #   Assets[:custom_emoji, emoji_id]
    # @example Generate a URL for a guild member's banner.
    #   Assets[:guild_member_banner, user_id, banner_hash, format]
    # @return [String, nil] the URL to the asset, or `nil` if the hash is `nil`.
    def self.[](type, *path, **query)
      if type != :sticker && type != :gif_sticker &&
         path.length >= 2 && path[-2].start_with?('a_')
        query[:animated] = true
      end

      query = unless query.tap(&:compact!).empty?
                "?#{URI.encode_www_form(query)}"
              end

      "#{format(ENDPOINTS[type.to_sym], *path)}#{query}"
    end
  end
end
