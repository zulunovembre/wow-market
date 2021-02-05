require './tests.rb'

my_test()

run Rack::URLMap.new({
                       "/" => TestAPI,
                       "/protected" => TestAuth
                     })
