$REGIONS = ["eu", "us", "kr", "tw"]

# ------------------------------------------------------------------------------

def blizz_auth(region, client_id, client_secret)  
  begin
    response = RestClient.post "https://#{client_id}:#{client_secret}@#{region}.battle.net/oauth/token", :grant_type => 'client_credentials'
    json = JSON.parse(response.body)
    return json["access_token"]
  rescue RestClient::Unauthorized => e
    json = JSON.parse(e.http_body)
    puts "error: #{json["error"]}: #{json["error_description"]}"
    return ""
  rescue => e
    puts "error: #{e.class}: #{e.message}"
    return ""
  end  
end

# ------------------------------------------------------------------------------

def app_auth(region, client_id, client_secret)
  if !$REGIONS.include?(region)
      puts "error: unknown region: #{region}"
      exit 1
    end
    
    access_token = blizz_auth(region, client_id, client_secret)
    if access_token.empty?
      exit 2
    end
    
    return access_token
end
