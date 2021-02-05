require 'sinatra/base'

require "../blizz.rb"

require "./utils.rb"

# ------------------------------------------------------------------------------

$LJUST = 80

# ------------------------------------------------------------------------------

class TestAPI < Sinatra::Base

  class << self
    attr_accessor :last_params
    attr_accessor :item_returned_json
    attr_accessor :media_returned_json
    attr_accessor :item_called
    attr_accessor :media_called
    attr_accessor :status
    attr_accessor :reset_status
    attr_accessor :first_req_time
    attr_accessor :last_req_time
    attr_accessor :nb_reqs
    attr_accessor :times
  end

  self.item_called = 0
  self.media_called = 0
  self.status = 200
  self.reset_status = false
  self.nb_reqs = 0
  self.times = []

  def self.reset()
    self.item_called = 0
    self.media_called = 0
    self.status = 200
    self.reset_status = false
    self.nb_reqs = 0
    self.times = []
  end
  
  def self.count()
    now = Time.now
    if TestAPI.nb_reqs == 0
      TestAPI.first_req_time = now
    end
    TestAPI.last_req_time = now
    TestAPI.times << now
    TestAPI.nb_reqs += 1
  end
  
  get '/data/wow/item/:id' do
    TestAPI.count()
    TestAPI.last_params = params.clone
    TestAPI.item_called += 1
    status TestAPI.status
    if TestAPI.reset_status == true
      TestAPI.status = 200
    end
    TestAPI.item_returned_json.call(params[:id], params[:locale])
  end

  get '/data/wow/media/item/:id' do
    TestAPI.count()
    TestAPI.last_params = params.clone
    TestAPI.media_called += 1
    status TestAPI.status
    if TestAPI.reset_status == true
      TestAPI.status = 200
    end
    TestAPI.media_returned_json.call(params[:id])
  end
  
end

# ------------------------------------------------------------------------------

class TestAuth < Sinatra::Base

  class << self
    attr_accessor :nb_auth
    attr_accessor :last_params
    attr_accessor :returned_json
    attr_accessor :received_username
    attr_accessor :received_password
    attr_accessor :returned_auth_result
  end

  self.nb_auth = 0

  def self.reset()
    self.nb_auth = 0
  end
  
  post '/oauth/token' do
    TestAuth.nb_auth += 1
    TestAuth.last_params = params.clone
    return TestAuth.returned_json
  end

  use Rack::Auth::Basic, "Protected Area" do |username, password|
    TestAuth.received_username = username
    TestAuth.received_password = password
    TestAuth.returned_auth_result
  end
  
end

# ------------------------------------------------------------------------------

def generate_name(id, locale)
  "#{id}-#{locale}"
end

# ------------------------------------------------------------------------------

def generate_item_json(id, locale)
  "{\"name\":\"#{generate_name(id, locale)}\"}"  
end

# ------------------------------------------------------------------------------

def generate_media(id)
  "http://localhost:4567/medias?id=#{id}"
end

# ------------------------------------------------------------------------------

def generate_media_json(id)
  "{\"assets\":[{\"value\":\"#{generate_media(id)}\"}]}"
end

# ------------------------------------------------------------------------------

def my_test()
  Thread.new do
    sleep(1)
    ($LJUST+2).times { print("-") }; puts
    begin

      test_pattern = ENV["TEST_PATTERN"]
      if test_pattern.nil?
        test_pattern = ".*"
      end
      
      if "all_fast".match(test_pattern)
        # INSTANCIATION
        assert_throw("Instanciation without any arguments", ArgumentError) { BlizzAPI.new() }
        assert_throw("Instanciation with one argument", ArgumentError) { BlizzAPI.new("eu") }
        assert_throw("Instanciation with first argument nil", ArgumentError) { BlizzAPI.new(nil, "test") }
        assert_throw("Instanciation with second argument nil", ArgumentError) { BlizzAPI.new("eu", nil) }
        assert_throw("Instanciation with first argument not string", ArgumentError) { BlizzAPI.new(42, "test") }
        assert_throw("Instanciation with second argument not string", ArgumentError) { BlizzAPI.new("eu", 42) }
        assert_throw("Instanciation with first argument empty string", ArgumentError) { BlizzAPI.new("", "test") }
        assert_throw("Instanciation with second argument empty string", ArgumentError) { BlizzAPI.new("eu", "") }
        assert_no_throw("Instanciation with correct arguments") { BlizzAPI.new("test_id", "test_secret") }

        # AUTHENTICATION FAILURE
        blz = BlizzAPI.new("test_id", "test_secret", {testing: true})
        TestAuth.returned_auth_result = false
        assert_throw("Throw on refused authentication", BlizzAPI::BadCredentialsError) { blz.fetch_item(25, :en_GB) }
        TestAuth.returned_auth_result = true
        TestAuth.returned_json = '[]'
        assert_throw("Throw on bad json received after auth (not a hash)", BlizzAPI::UnexpectedJSONError) { blz.fetch_item(25, :en_GB) }
        TestAuth.returned_json = '{}'
        assert_throw("Throw on bad json received after auth (no \"access_token\" key)", BlizzAPI::UnexpectedJSONError) { blz.fetch_item(25, :en_GB) }
        TestAuth.returned_json = '{"access_token":42}'
        assert_throw("Throw on bad json received after auth (\"access_token\" value not a string)", BlizzAPI::UnexpectedJSONError) { blz.fetch_item(25, :en_GB) }
        TestAuth.returned_json = '{"access_token":"test_token"}'

        
        # AUTHENTICATION SUCCESS + ITEM API
        TestAPI.item_returned_json = Proc.new { '{"id": 25, "name": "test_name"}' }
        data = {}
        assert_no_throw("No throw on correct JSON") { data = blz.fetch_item(25, :en_GB) }
        assert_eq("Expected username", "test_id", TestAuth.received_username)
        assert_eq("Expected password", "test_secret", TestAuth.received_password)
        assert_eq("Params contains grant_type", true, TestAuth.last_params.has_key?(:grant_type))
        assert_eq("Grant_type header value is \"client_credentials\"", "client_credentials", TestAuth.last_params[:grant_type])

        assert_eq("Item get handler was called", 1, TestAPI.item_called)
        assert_eq("Expected id param", "25", TestAPI.last_params[:id])
        assert_eq("Expected namespace", "static-eu", TestAPI.last_params[:namespace])
        assert_eq("Expected locale", "en_GB", TestAPI.last_params[:locale])
        assert_eq("Expected token", "test_token", TestAPI.last_params[:access_token])
        assert_eq("Expected data", JSON.parse(TestAPI.item_returned_json.call()), data)

        
        # NORMAL BEHAVIOR
        nb_auth = TestAuth.nb_auth
        blz.fetch_item(25, :en_GB)
        assert_eq("Client did not try to authenticate again", nb_auth, TestAuth.nb_auth)
        assert_eq("Item get handler was called", 2, TestAPI.item_called)

        
        # RE AUTH ON 401
        TestAPI.status = 401
        TestAPI.reset_status = true
        assert_no_throw("No throw on re authentication") { data = blz.fetch_item(25, :en_GB) }
        assert_eq("Client tried to authenticate again on 401", nb_auth + 1, TestAuth.nb_auth)
        assert_eq("Item get handler was called two times", 4, TestAPI.item_called)
        assert_eq("Expected data", JSON.parse(TestAPI.item_returned_json.call()), data)

        
        # THROW ON DOUBLE 401
        TestAPI.status = 401
        TestAPI.reset_status = false
        assert_throw("Throw on double 401", BlizzAPI::UnexpectedAuthError) { blz.fetch_item(25, :en_GB) }

        
        # MEDIA API
        TestAPI.status = 200
        TestAPI.media_returned_json = Proc.new { '{' }
        assert_throw("Throw on incorrect JSON", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        TestAPI.media_returned_json = Proc.new { '[]' }
        assert_throw("Throw on not hash", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        TestAPI.media_returned_json = Proc.new { '{}' }
        assert_throw("Throw on no \"assets\" key", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        TestAPI.media_returned_json = Proc.new { '{"assets":42}' }
        assert_throw("Throw on \"assets\" not an array", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        TestAPI.media_returned_json = Proc.new { '{"assets":[{"value":"test"},{"value":"test"}]}' }
        assert_throw("Throw on \"assets\" array not good size", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        TestAPI.media_returned_json = Proc.new { '{"assets":[42]}' }
        assert_throw("Throw on \"assets\" array first item not a hash", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        TestAPI.media_returned_json = Proc.new { '{"assets":[{}]}' }
        assert_throw("Throw on no \"value\" key in hash", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        TestAPI.media_returned_json = Proc.new { '{"assets":[{"value":42}]}' }
        assert_throw("Throw on no \"value\" not a string", BlizzAPI::UnexpectedJSONError) { blz.fetch_item_media(25) }
        returned_uri = "test_uri"
        TestAPI.media_returned_json = Proc.new { "{\"assets\":[{\"value\":\"#{returned_uri}\"}]}" }
        uri = ""
        assert_no_throw("No throw on correct JSON") { uri = blz.fetch_item_media(25) }
        assert_eq("Expected URI (\"#{returned_uri}\")", returned_uri, uri)
      end

      min = 90
      max = 100
      
      if "reqs_per_sec".match(test_pattern)
        # DO_REQ REQUESTS PER SECOND LIMITATION
        TestAPI.item_returned_json = Proc.new {|id, locale| generate_item_json(id, locale)}
        TestAPI.media_returned_json = Proc.new {|id| generate_media_json(id)}
        # fixme: should be 100
        TestAPI.nb_reqs = 0
        TestAPI.times = []
        nb_reqs = 500
        lp = LinePercent.new("Requests received / second greater than #{min} but lesser than #{max}", $LJUST, nb_reqs)
        blz = BlizzAPI.new("test_id", "test_secret", {testing: true})
        threads = []
        (0..nb_reqs).each do |n|
          threads << Thread.new do
            blz.send(:do_req, :eu, :en_GB, :item, 0, false)
          end
        end
        threads.each do |t|
          t.join
          lp.inc()
        end
        for i in 0..nb_reqs-100
          assert_gt("Requests / second never reached 100", 1, TestAPI.times[i + 99] - TestAPI.times[i], true)
        end
        assert_gt("Requests per second received greater than #{min}", min, TestAPI.nb_reqs / (TestAPI.last_req_time - TestAPI.first_req_time), true)
        assert_le("Requests per second received lesser than #{max}", max, TestAPI.nb_reqs / (TestAPI.last_req_time - TestAPI.first_req_time), true)
        lp.ok()
      end

      if "fetch_all_items".match(test_pattern)
        # FETCH_ALL_ITEMS
        blz = BlizzAPI.new("test_id", "test_secret", {testing: true})
        assert_throw("fetch_all_items throws ArgumentError on first_id lesser than zero", ArgumentError) {blz.fetch_all_items(-1, 0){}}
        assert_throw("fetch_all_items throws ArgumentError on last_id lesser than zero", ArgumentError) {blz.fetch_all_items(-2, -1){}}
        assert_throw("fetch_all_items throws ArgumentError on last_id lesser than first_id", ArgumentError) {blz.fetch_all_items(1, 0){}}
        assert_throw("fetch_all_items throws ArgumentError on media param not true or false", ArgumentError) {blz.fetch_all_items(0, 1, [], 42){}}
        assert_throw("fetch_all_items throws ArgumentError on locales param not an array", ArgumentError) {blz.fetch_all_items(0, 1, 42){}}
        assert_throw("fetch_all_items throws ArgumentError on no block given", ArgumentError) {blz.fetch_all_items(0, 1, [], true)}
        assert_throw("fetch_all_items throws ArgumentError on bad locale given", ArgumentError) {blz.fetch_all_items(0, 1, [:bad], true)}

        TestAPI.item_returned_json = Proc.new {|id, locale| generate_item_json(id, locale)}
        TestAPI.media_returned_json = Proc.new {|id| generate_media_json(id)}
        
        def test_fetch_all_items(test_name, blz, first_id, last_id, locales, fetch_media)
          nb_items = last_id - first_id + 1
          prev_id = -1
          lp = LinePercent.new("#{test_name}", $LJUST, nb_items)
          $nb_call = 0
          assert_no_throw("#{test_name}: no throw", true) do
            blz.fetch_all_items(first_id, last_id, locales, fetch_media) do |id, infos, media|
              $nb_call += 1
              
              debug = Proc.new do
                puts "#{id}"
                infos.each do |locale, info|
                  puts "\t#{locale.to_s}: #{JSON.generate(info)}"
                end
                puts "\tmedia: #{media}"
              end

              assert_gt("#{test_name}: id #{id}: Current id greater than previous", prev_id, id, true) { debug.call() }
              assert_true("#{test_name}: id #{id}: Infos is a hash", infos.is_a?(Hash), true) { debug.call() }
              assert_eq("#{test_name}: id #{id}: Infos has the good size", locales.size, infos.size, true) { debug.call() }
              locales.each do | locale |
                assert_true("#{test_name}: id #{id}: Infos has #{locale} key", infos.has_key?(locale), true)
              end
              infos.each do |locale, data|
                assert_true("#{test_name}: id #{id}: Data inside info[locale] is hash", data.is_a?(Hash), true)
                assert_eq("#{test_name}: id #{id}: Data size is expected", 1, data.size(), true)
                assert_true("#{test_name}: id #{id}: Data has key \"name\"", data.has_key?("name"), true)
                assert_eq("#{test_name}: id #{id}: Data[\"name\"] has the expected value", generate_name(id, locale), data["name"], true)
              end
              assert_eq("#{test_name}: id #{id}: Media has the expected value", fetch_media ? generate_media(id) : nil, media, true)
              lp.inc()
            end
          end
          lp.ok()
        end
        
        locales = [:en_GB, :fr_FR, :es_ES]
        blz = BlizzAPI.new("test_id", "test_secret", {testing: true})
        
        TestAuth.reset()
        TestAuth.returned_auth_result = true
        TestAuth.returned_json = '{"access_token":"test_token"}'
        TestAPI.reset()
        TestAPI.status = 401
        TestAPI.reset_status = true
        test_fetch_all_items("Fetch_all_items, auth and retry on 401", blz, 0, 0, [:en_GB], false)
        assert_eq("Block was called 1 time", 1, $nb_call)
        assert_eq("Client has authenticated itself one time", 1, TestAuth.nb_auth)
        assert_eq("Server has received expected number of requests", 2, TestAPI.times.size())

        TestAPI.reset()
        TestAPI.status = 500
        TestAPI.reset_status = true
        test_fetch_all_items("Fetch_all_items, retry on 500", blz, 0, 0, [:en_GB], false)
        assert_eq("Block was called 1 time", 1, $nb_call)
        assert_eq("Server has received expected number of requests", 2, TestAPI.times.size())

        TestAPI.reset()
        TestAPI.status = 404
        called = false
        assert_no_throw("1 item, 404, no throw") { blz.fetch_all_items(0, 0, [:en_GB], false) { called = true } }
        assert_false("Block was not called", called)
        assert_eq("Server has received expected number of requests", 1, TestAPI.times.size())

        TestAPI.reset()
        test_fetch_all_items("fetch_all_items 1 item, 1 locale", blz, 0, 0, [:en_GB], true)
        assert_eq("Block was called 1 time", 1, $nb_call)
        test_fetch_all_items("fetch_all_items 1 item, 2 locales", blz, 0, 0, [:en_GB, :fr_FR], true)
        assert_eq("Block was called 1 time", 1, $nb_call)
        test_fetch_all_items("fetch_all_items 2 items, 1 locale", blz, 0, 1, [:en_GB], true)
        assert_eq("Block was called 2 times", 2, $nb_call)
        test_fetch_all_items("fetch_all_items 2 items, 2 locales", blz, 0, 1, [:en_GB, :fr_FR], true)
        assert_eq("Block was called 2 times", 2, $nb_call)
        TestAPI.nb_reqs = 0
        TestAPI.times = []
        nb_items = 500
        sleep(1)
        blz = BlizzAPI.new("test_id", "test_secret", {testing: true})
        test_fetch_all_items("fetch_all_items 500 items, 2 locales", blz, 1, nb_items, [:en_GB, :fr_FR], true)
        assert_eq("Block was called 500 times", 500, $nb_call)
        assert_eq("Server has received expected number of requests", nb_items * 3, TestAPI.times.size())
        for i in 0..nb_items * 3 - 100
          assert_gt("Requests / second never reached 100", 1, TestAPI.times[i + 99] - TestAPI.times[i], true)
        end
        assert_gt("Requests per second received greater than #{min}", min, TestAPI.nb_reqs / (TestAPI.last_req_time - TestAPI.first_req_time))
        assert_le("Requests per second received lesser than #{max}", max, TestAPI.nb_reqs / (TestAPI.last_req_time - TestAPI.first_req_time))
      end
      
    rescue => e
      puts "ERROR: #{e.class.name}"
      puts e.message
      puts e.backtrace
      quit()
    end
    
    quit(0)
    
  end

end
