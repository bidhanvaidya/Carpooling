class Stop < ActiveRecord::Base
geocoded_by :address
reverse_geocoded_by :latitude, :longitude

belongs_to :post
after_validation :geocode, :reverse_geocode, :simplified_address


def simplified_address
result=Geocoder.search(self.address).first
self.city= result.city
self.state = result.state_code
self.country = result.country
end
end
