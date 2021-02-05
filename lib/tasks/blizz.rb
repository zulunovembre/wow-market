require 'rest-client'

class BlizzAPI

  class BlizzError < RuntimeError
    def initialize(message)
      super(message)
    end
  end

  class BadCredentialsError < BlizzError
    def initialize()
      super("Bad credentials")
    end
  end

  class UnexpectedJSONError < BlizzError
    def initialize()
      super("Received unexpected JSON from Blizzard")
    end
  end

  class UnexpectedAuthError < BlizzError
    def initialize()
      super("Could not refresh the access token")
    end
  end

  # ------------------------------------------------------------------------------

  class << self
    attr_accessor :REGIONS
    attr_accessor :LOCALES
    attr_accessor :REQS_PER_SEC_DEFAULT
    attr_accessor :AUTH_HOST
    attr_accessor :API_HOST
    attr_accessor :URIS
    attr_accessor :NAMESPACES
  end

  self.REGIONS = {
    eu: "eu",
    us: "us",
    kr: "kr",
    tw: "tw"
  }
  self.LOCALES = {
    en_GB: "en_GB",
    # en_US: "en_US",
    de_DE: "de_DE",
    es_ES: "es_ES",
    # es_MX: "es_MX",
    fr_FR: "fr_FR",
    it_IT: "it_IT",
    ru_RU: "ru_RU",
    pt_BR: "pt_BR",
    ko_KR: "ko_KR",
    zh_TW: "zh_TW"
  }
  self.REQS_PER_SEC_DEFAULT = 100
  self.AUTH_HOST = "battle.net"
  self.API_HOST = "api.blizzard.com"
  self.URIS = {
    item: "item",
    media: "media/item"
  }
  self.NAMESPACES = {
    item: "static",
    media: "static"
  }

  # ------------------------------------------------------------------------------

  def initialize(client_id, client_secret, opts = {})
    if client_id.nil? || client_secret.nil?
      raise ArgumentError.new("At least one argument is nil")
    elsif !client_id.is_a?(String) || !client_secret.is_a?(String)
      raise ArgumentError.new("At least one argument is not a string")
    elsif client_id.empty? || client_secret.empty?
      raise ArgumentError.new("At least one argument is an empty string")
    elsif opts.has_key?(:reqs_per_sec) && (!opts[:reqs_per_sec].is_a?(Integer) || opts[:reqs_per_sec] <= 0)
      raise ArgumentError.new("Option reqs_per_sec is not an integer or is <= 0")
    end
    @client_id = client_id
    @client_secret = client_secret
    if opts.has_key?(:reqs_per_sec)
      @reqs_per_sec = opts[:reqs_per_sec]
    else
      @reqs_per_sec = BlizzAPI.REQS_PER_SEC_DEFAULT
    end
    if opts.has_key?(:testing)
      @testing = opts[:testing]
    end
    @accesses = {
      eu: {authenticated: false, token: ""},
      us: {authenticated: false, token: ""},
      kr: {authenticated: false, token: ""},
      tw: {authenticated: false, token: ""},
    }
    @requests_times = []
    @mutex = Mutex.new
  end

  # ------------------------------------------------------------------------------

  private
  def get_auth_uri(region)
    if @testing == true
      return "http://#{@client_id}:#{@client_secret}@localhost:4567/protected/oauth/token"
    else
      return "https://#{@client_id}:#{@client_secret}@#{region.to_s}.#{BlizzAPI.AUTH_HOST}/oauth/token"
    end
  end

  # ------------------------------------------------------------------------------

  private
  def get_api_uri(region, req_type, param)
    common_part = "/data/wow/#{BlizzAPI.URIS[req_type]}/#{param}"
    if @testing == true
      return "http://localhost:4567#{common_part}"
    else
      return "https://#{region.to_s}.#{BlizzAPI.API_HOST}#{common_part}"
    end
  end

  # ------------------------------------------------------------------------------

  public
  def auth(region)
    begin
      # puts "AUTH URI: #{get_auth_uri(region)}"
      response_json = RestClient.post(get_auth_uri(region), :grant_type => 'client_credentials')
      response_data = JSON.parse(response_json.body)
      if !response_data.is_a?(Hash) || !response_data["access_token"].is_a?(String)
        raise UnexpectedJSONError
      end
      @accesses[region][:token] = response_data["access_token"]
      @accesses[region][:authenticated] = true
    rescue RestClient::Unauthorized
      raise BadCredentialsError
    rescue JSON::ParserError
      raise UnexpectedJSONError
    end
  end

  # ------------------------------------------------------------------------------

  private
  def send_req(region, locale, req_type, param)
    uri = get_api_uri(region, req_type, param)
    # puts "REQ URI: #{uri}"
    params = {namespace: "#{BlizzAPI.NAMESPACES[req_type]}-#{region.to_s}",
              locale: locale.to_s,
              access_token: @accesses[region][:token]}
    begin
      return JSON.parse(RestClient.get(uri, {params: params}))
    rescue JSON::ParserError
      raise UnexpectedJSONError
    ensure
      @requests_times << Time.now
    end
  end

  # ------------------------------------------------------------------------------

  private
  def time_limit(wait = false)
    now = Time.now

    idx = @requests_times.index {|time|now - time < 1}

    if idx.nil?
      return
    end

    ridx = @requests_times.size - idx

    if ridx >= @reqs_per_sec
      time_to_sleep = 1
    # elsif (ridx == 99 && wait == false) || (ridx <= 99 && wait == true)
    elsif (ridx == @reqs_per_sec - 1)
      time_to_sleep = 1 - (@requests_times.last - @requests_times[idx])
    else
      time_to_sleep = 0
    end

    if time_to_sleep > 0
      # puts "SLEEPING #{time_to_sleep}, ridx = #{ridx}"
      sleep(time_to_sleep)
      now = Time.now
    end

    @requests_times.delete_if {|time|now - time >= 1}
  end

  # ------------------------------------------------------------------------------

  private
  def _do_req(region, locale, req_type, param, auth = true)
    if auth == true && @accesses[region][:authenticated] == false
      auth(region)
    end

    if auth == false
      return send_req(region, locale, req_type, param)
    end

    begin
      return send_req(region, locale, req_type, param)
    rescue RestClient::Unauthorized
      auth(region)
      begin
        return send_req(region, locale, req_type, param)
      rescue RestClient::Unauthorized
        raise UnexpectedAuthError
      end
    end
  end

  # ------------------------------------------------------------------------------

  public
  def do_req(region, locale, req_type, param, auth = true)
    begin
      @mutex.lock
      _do_req(region, locale, req_type, param, auth)
    ensure
      time_limit()
      @mutex.unlock
    end
  end

  # ------------------------------------------------------------------------------

  public
  def fetch_item(id, locale)
    return do_req(:eu, locale, :item, id)
  end

  # ------------------------------------------------------------------------------

  def get_media(data)
    if !data.is_a?(Hash) || !data.has_key?("assets") || !data["assets"].is_a?(Array) || !(data["assets"].size == 1) || !data["assets"][0].is_a?(Hash) || !data["assets"][0].has_key?("value") || !data["assets"][0]["value"].is_a?(String)
      raise UnexpectedJSONError
    end
    return data["assets"][0]["value"]
  end

  # ------------------------------------------------------------------------------

  public
  def fetch_item_media(id)
    data = do_req(:eu, :en_GB, :media, id)
    return get_media(data)
  end

  # ------------------------------------------------------------------------------

  public
  def fetch_all_items(first_id = 0, last_id = 200000, locales = BlizzAPI.LOCALES.keys(), fetch_media = true, &block)
    if !first_id.is_a?(Integer) || !last_id.is_a?(Integer) || first_id < 0 || last_id < 0 || last_id < first_id
      raise ArgumentError.new("First_id or last_id is not an integer, not greater or equal than zero or last_id is lesser then first_id")
    elsif !fetch_media.is_a?(TrueClass) && !fetch_media.is_a?(FalseClass)
      raise ArgumentError.new("Media is not a boolean")
    elsif !locales.is_a?(Array)
      raise ArgumentError.new("Locales is not an array")
    elsif block.is_a?(NilClass)
      raise ArgumentError.new("Block not given")
    end

    locales.uniq!()

    locales.each do |key|
      if !BlizzAPI.LOCALES.keys().include?(key)
        raise ArgumentError.new("Unknown locale: #{key}")
      end
    end


    remaining = @reqs_per_sec - 1
    now = Time.now
    idx =  @requests_times.index {|time|now - time < 1}
    if !idx.nil?
      remaining -= (@requests_times.size - idx)
    end
    i = first_id
    while i <= last_id
      tasks = []
      items = {}

      for id in i..i + [99, last_id - i].min
        tasks << {type: locales.first, id: id}
      end

      while !tasks.empty?
        threads = []
        reauth = false

        while !tasks.empty? && remaining > 0
          nb_req = [remaining, tasks.size].min()
          # puts "nb reqs: #{nb_req}"
          nb_req.times do |n|
            threads << Thread.new(tasks[n]) do |task|
              # puts "#{task.inspect}"
              error = true
              begin
                if task[:type] == :media
                  media_str = get_media(_do_req(:eu, :en_GB, :media, task[:id], false))
                  items[task[:id]][:media] = media_str
                else
                  item_json = _do_req(:eu, task[:type], :item, task[:id], false)
                  if task[:type] == locales.first
                    items[task[:id]] = {}
                  end
                  items[task[:id]][task[:type]] = item_json
                end
              rescue RestClient::Unauthorized
                # puts "401"
                reauth = true
                tasks << {type: task[:type], id: task[:id]}
              rescue RestClient::InternalServerError
                # puts "500"
                tasks << {type: task[:type], id: task[:id]}
              rescue => e
              # puts "OTHER ERROR: #{e.class.name} #{e.message}"
              else
                error = false
              end

              if error == false && task[:type] == locales.first
                (locales - [locales.first]).each do |locale|
                  tasks << {type: locale, id: task[:id]}
                end
                if fetch_media == true
                  tasks << {type: :media, id: task[:id]}
                end
              end
            end
          end
          tasks.shift(nb_req)
          remaining -= nb_req
          if remaining == 0
            time_limit()
            remaining = @reqs_per_sec - 1
          end
        end

        threads.each {|t| t.join() }
        threads.clear()

        # time_limit(true)

        if reauth == true
          auth(:eu)
          reauth = false
        end

      end

      items = items.to_a.sort { |a,b| a[0] <=> b[0] }

      items.each do |item|
        media = item[1].delete(:media)
        block.call(item[0], item[1], media)
      end

      items.clear()

      i += 100
    end
  end

end
