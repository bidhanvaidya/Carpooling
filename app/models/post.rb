class Post < ActiveRecord::Base
  attr_accessible :startdate, :time, :user_id, :startLocation, :note, :closed, :contribution, :is_driving,:start_attributes, :finish_attributes, :stops_attributes
  after_create :save_location
 belongs_to :user
  has_one :finish, :dependent => :destroy
  has_one :start, :dependent => :destroy
  has_many :bookings
has_many :stops, :dependent => :destroy
 accepts_nested_attributes_for :start, :reject_if => lambda { |a| a[:address].blank? }, :allow_destroy => true
accepts_nested_attributes_for :finish, :reject_if => lambda { |a| a[:address].blank? }, :allow_destroy => true
  
accepts_nested_attributes_for :stops, :reject_if => lambda { |a| a[:address].blank? }, :allow_destroy => true

validates :startdate, :presence => true








  def save_location
		#Location.create(address: self.startLocation, post_id: self.id, status: "start")
		#Location.create(address: self.endLocation, post_id: self.id, status: "end")
		
  end
   
  
  
  
end
