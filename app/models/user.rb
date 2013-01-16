class User < ActiveRecord::Base
has_many :friends
has_one :profile
after_create :save_friends
has_many :posts
has_many :bookings
has_many :reviews
has_many :educations
#def self.create_with_omniauth(auth)
 # create! do |user|
  #  user.provider = auth["provider"]
   # user.uid = auth["uid"]
    #user.token = auth["credentials"]["token"]
    #user.name = auth["info"]["name"]
    
 # end
  
  #end
    def self.from_omniauth(auth)
  where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
    user.provider = auth.provider
    user.uid = auth.uid
    user.name = auth.info.name
    user.token = auth.credentials.token
    #user.oauth_expires_at = Time.at(auth.credentials.expires_at)
    user.save!
  end
  
def save_friends
	user=FbGraph::User.me(self.token).fetch
	Profile.create(:name=> user.name,
      :first_name=>user.first_name,
      :last_name=>user.last_name,
      :gender=>user.gender,
      :link=>user.link,
      :verified=>user.verified,
      :date_of_birth=>user.birthday,
      :relationship_status=>user.relationship_status,
      :current_location=>user.location.try(:name),
      :hometown=>user.hometown.try(:name),
      :user_id =>self.id,
      :email => user.email,
      :paypal_email => user.email
      )
	user.friends.each do |friend| 
		Friend.create(:user_id=> self.id, :uid=> friend.identifier, :name => friend.name) 
	end 
	if !user.education.nil?
			user.education.each do |education|
			if !education.year.nil?
				Education.create(user_id: self.id, type: education.type, name: education.school.name, year: education.year.name)
			else
				Education.create(user_id: self.id, type: education.type, name: education.school.name, year: nil)
			end
		end
	end


end

end

