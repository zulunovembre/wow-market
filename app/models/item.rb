class Item < ApplicationRecord
  has_one :item_media
  has_many :stats
  has_one :item_name
  has_many :auctions
end
