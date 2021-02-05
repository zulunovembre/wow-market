require "./lib/tasks/blizz.rb"

def store_item(id, infos, media)
  # $items.each do |id, data|
  #   items << {
  #     item_id: id,
  #     quality: data[:quality],
  #     level: data[:level],
  #     required_level: data[:required_level],
  #     item_class: data[:item_class],
  #     item_subclass: data[:item_subclass],
  #     inventory_type: data[:inventory_type],
  #     purchase_price: data[:purchase_price],
  #     sell_price: data[:sell_price],
  #     max_count: data[:max_count],
  #     is_equippable: data[:is_equippable],
  #     is_stackable: data[:is_stackable],
  #     binding: data[:binding],
  #     unique: data[:unique],
  #     created_at: Time.now,
  #     updated_at: Time.now
  #   }
  #   # store_record(id, data)
  #   lp.inc()
  # end
  # item_records = Item.insert_all(items, returning: %w(id item_id)) unless items.empty?

  # names = []
  # item_medias = []
  # weapons = []
  # stats = []
  # item_records.each do |item_record|
  #   data = $items[item_record["item_id"]]
  #   data[:name].each do |locale, name|
  #     names << {
  #       item_id: item_record["id"],
  #       locale: locale,
  #       name: name,
  #       created_at: Time.now,
  #       updated_at: Time.now
  #     }
  #   end
  #   item_medias << {
  #     item_id: item_record["id"],
  #     url: data[:media],
  #     created_at: Time.now,
  #     updated_at: Time.now
  #   }
  #   if data[:info_table] == "weapons"
  #     weapons << {
  #       item_id: item_record["id"],
  #       dmg_min: data[:dmg_min],
  #       dmg_max: data[:dmg_max],
  #       attack_speed: data[:attack_speed],
  #       dps: data[:dps],
  #       created_at: Time.now,
  #       updated_at: Time.now
  #     }
  #   end
  #   if !data[:stats].nil?
  #     data[:stats].each do |stat|
  #       stats << {
  #         item_id: item_record["id"],
  #         stat_type: stat[:stat_type],
  #         value: stat[:value],
  #         created_at: Time.now,
  #         updated_at: Time.now
  #       }
  #     end
  #   end        
  # end
  # blz.fetch_all_items(range_start, range_end)
end

# ------------------------------------------------------------------------------

namespace :items do
  task :fetch_all, [:client_id, :client_secret, :start_id, :end_id] => :environment do |task, args|

    if args[:client_id].nil? || args[:client_secret].nil? || (!args[:start_id].nil? && args[:start_id].to_i < 0) || (!args[:end_id].nil? && args[:end_id].to_i < 0) || (!args[:start_id].nil? && !args[:end_id].nil? && args[:end_id].to_i < args[:start_id].to_i)
      puts "Usage: rake items:fetch_all [<client_id>,<client_secret>]"
      puts "or     rake items:fetch_all [<client_id>,<client_secret>,<id_to_fetch>]"
      puts "or     rake items:fetch_all [<client_id>,<client_secret>,<start_id>,<end_id>]"
      puts ""
      puts "start_id must be inferior or equal to end_id and both must be >= 0"
      exit 1
    end
    
    if !args[:start_id].nil?
      range_start = args[:start_id].to_i
      if !args[:end_id].nil?
        range_end = args[:end_id].to_i
      else
        range_end = range_start
      end
    else
      range_start = 0
      range_end = 200000
    end

    begin
      blz = BlizzAPI.new(args[:client_id], args[:client_secret])
      blz.fetch_all_items(range_start, range_end) do |id, infos, media|
        puts "#{id}"
        infos.each do |locale, info|
          puts "\t#{locale.to_s}: #{info["name"]}"
        end
        puts "\tmedia: #{media}"
      end
      rescue => e
        puts
        puts "Critical error: #{e.message}"
      end
      
    end
  end
