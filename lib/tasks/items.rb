$LOCALES = ["en_GB", "de_DE", "es_ES", "fr_FR", "it_IT", "ru_RU", "pt_BR", "es_MX", "ko_KR", "zh_TW"]

# ------------------------------------------------------------------------------

def fetch_item_json(id, locale)
  response = RestClient.get "https://#{$region}.api.blizzard.com/data/wow/item/#{id}", {params: {:namespace => "static-#{$region}", :locale => locale, :access_token => $access_token}}
  return response
end

# ------------------------------------------------------------------------------

def fetch_item_info(id, locale)
  raw = fetch_item_json(id, locale)
  item_info = JSON.parse(raw)
  return item_info
end

# ------------------------------------------------------------------------------

def fetch_item_name(id, locale)
  item_info = fetch_item_info(id, locale)
  return item_info["name"]
end

# ------------------------------------------------------------------------------

def fetch_item_media(id)
  response = RestClient.get "https://#{$region}.api.blizzard.com/data/wow/media/item/#{id}", {params: {:namespace => "static-#{$region}", :locale => "en_GB", :access_token => $access_token}}
  json = JSON.parse(response)
  if !json.is_a?(Hash) || !json.has_key?("assets") || !json["assets"].is_a?(Array) || !json["assets"][0].has_key?("value") || !json["assets"][0]["value"].is_a?(String)
    return ""
  end
  return json["assets"][0]["value"]
end
