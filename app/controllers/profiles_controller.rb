class ProfilesController < ApplicationController

before_filter :editing, :only=> [:update, :show, :accept, :reject, :accept_and_close]
def index
  @user= User.find(params[:user_id])
 @profile= @user.profile
 @posts= @user.posts.paginate(:page => params[:page], :per_page => 3)
  @page = FbGraph::User.me(@user.token).fetch
  if current_user == @user
    @inbox=@profile.receipts.inbox.where(trashed: false)
    @sentbox=  @profile.receipts.sentbox.where(trashed: false) 
    @trash= @profile.receipts.trash
  end
  @booking_offers= Booking.where(post_id: @posts)
  @booking_requests= Booking.where(user_id: @user)
   @rev= @profile.reviews
end
def send_message
   body=params[:body]
    @user= User.find(params[:user_id]).profile
   current_user.profile.send_message(@user, body, ("Message from "+current_user.name + " to "+ @user.first_name))
    redirect_to posts_path
end
def reply_message
body=params[:body]
    receipt= Receipt.find(params[:receipt])
current_user.profile.reply_to_sender(receipt, body)
 redirect_to user_profiles_path(current_user)
end
def trash
user= User.find(params[:user_id]).profile
body=params[:body]
    receipt= user.receipts.find(params[:receipt])
receipt.move_to_trash
 redirect_to user_profiles_path(current_user)
end
 
def show
@profile= User.find(params[:user_id]).profile
 @page = FbGraph::User.me(@profile.user.token).fetch
  @user= User.find(params[:user_id]).profile

respond_to do |type|
      type.html
      type.json {render :json => @profile}
    end
end
  def update
    
  @profile= User.find(params[:user_id]).profile
    if @profile.update_attributes!(params[:profile])
      respond_to do |format|
       
        format.json { render :json => @profile }
      end
    else
      respond_to do |format|
        
        format.json { render :nothing =>  true }
      end
    end
     
  end
  		def editing
				@profile= User.find(params[:user_id]).profile
					if current_user == @profile.user
						true
					else
						redirect_to posts_path
				end
		end
		def accept #accept bookings
		@booking= Booking.find(params[:booking])
		@booking.update_attributes(accepted: true, rejected: false)
		redirect_to :back
		end
		def reject #reject bookings
				@booking= Booking.find(params[:booking])
		@booking.update_attributes(rejected: true, accepted: false)
		redirect_to :back
		end
		def accept_and_close #accept bookings and close post
						@booking= Booking.find(params[:booking])
						@post= @booking.post
		@booking.update_attributes(rejected: false, accepted: true)
		@post.update_attributes(close: true)
		redirect_to :back
		end
		def review_create
		@profile= User.find(params[:user_id]).profile
		@review = Review.create(review: params[:review], rating: params[:rating], user_id: current_user, profile_id: @profile.id )
		redirect_to :back
		 
		end
end
