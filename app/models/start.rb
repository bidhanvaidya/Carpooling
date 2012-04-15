class Start < ActiveRecord::Base
geocoded_by :address
reverse_geocoded_by :latitude, :longitude
after_validation :geocode, :reverse_geocode
belongs_to :post
end
