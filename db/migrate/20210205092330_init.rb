class Init < ActiveRecord::Migration[6.0]
  def change
    create_table :item_medias do |t|
      t.belongs_to :item
      t.string :url
      t.timestamps
    end

    create_table :weapons do |t|
      t.belongs_to :item
      t.integer :dmg_min
      t.integer :dmg_max
      t.string :damage_class
      t.integer :attack_speed
      t.float :dps
      t.timestamps
    end

    create_table :stats do |t|
      t.belongs_to :item
      t.string :stat_type
      t.integer :value
      t.timestamps
    end

    create_table :item_names do |t|
      t.belongs_to :item
      t.string :locale
      t.string :name
      t.timestamps
    end
    
    create_table :items do |t|
      t.integer :item_id, index: true
      t.string :quality
      t.integer :level
      t.bigint :required_level
      t.integer :item_class
      t.integer :item_subclass
      t.integer :inventory_type
      t.integer :purchase_price
      t.integer :sell_price
      t.integer :max_count
      t.boolean :is_equippable
      t.boolean :is_stackable
      t.string :binding
      t.string :unique
      t.string :info_table
      t.integer :info_id
      t.timestamps
    end
    
    create_table :auctions do |t|
      t.belongs_to :item
      t.bigint :auction_id, index: true
      t.integer :true_item_id
      t.string :owner
      t.string :region
      t.string :owner_realm
      t.integer :quantity
      t.bigint :buyout
      t.bigint :bid
      t.string :time_left
      t.timestamps
    end

    create_table :realms do |t|
      t.belongs_to :item
      t.string :region
      t.string :name
      t.string :slug
      t.string :battlegroup
      t.string :locale
      t.string :population
      t.timestamps
    end
  end
end
