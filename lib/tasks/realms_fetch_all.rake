require "./lib/tasks/blizz.rb"

namespace :realms do
  task :fetch_all, [:client_id, :client_secret] => :environment do |task, args|

    if args[:client_id].nil? || args[:client_secret].nil?
      puts "Usage: rake realms:fetch_all [<client_id>,<client_secret>]"
      exit 1
    end
    
    # blizz = Blizz.new(args[:region], args[:client_id], args[:client_secret])

    # print("Authenticating:".ljust(30))
    # begin
    #   blizz.auth()
    # rescue => e
    #   puts("ERROR")
    #   puts("#{e.message}")
    #   exit 2
    # end
    # puts("OK")

    
  end
end
