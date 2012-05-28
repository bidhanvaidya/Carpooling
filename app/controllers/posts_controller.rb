class PostsController < ApplicationController
before_filter :authenticate_user, :except=> [:show, :index, :search, :new, :create]
before_filter :facebook
before_filter :editing, :only=> [:edit, :update]
  def index
    @posts = Post.where('startdate >? AND closed=?', Date.yesterday, false).all
		@searchresults= []
		@matches = 0
		@educations = current_user.educations if current_user
if params[:start].present? && params[:finish].present?
      #@post_with_location= Post.find_by_sql("select * from posts inner join locations on locations.post_id=posts.id")
      
				if params[:date]==""
					@start_locations= Start.near(params[:start], 1, :order => :distance).includes(:post).where(post_id: @posts).all
					@end_locations= Finish.near(params[:finish], 1, :order => :distance).includes(:post).where(post_id: @posts)
					@stops1= Stop.near(params[:start], 1, :order => :distance).includes(:post).where(post_id: @posts)
					@stops2= Stop.near(params[:finish], 1, :order => :distance).includes(:post).where(post_id: @posts)
				else
					post=Post.where('startdate = ?', params[:date]).all
					@start_locations= Start.near(params[:start], 1, :order => :distance).joins(:post).where(post_id: post).all
					@end_locations= Finish.near(params[:finish], 1, :order => :distance).joins(:post).where(post_id: post)
					@stops1= Stop.near(params[:start], 1, :order => :distance).includes(:post).where(post_id: post)
					@stops2= Stop.near(params[:finish], 1, :order => :distance).includes(:post).where(post_id: post)
				end
						
						
						for start_location in @start_locations
							if !@end_locations.find_by_post_id(start_location.post.id).nil? 
								post=start_location.post
								@searchresults.push post		   
								@matches = @matches + 1
							end
							if !@stops2.find_by_post_id(start_location.post.id).nil?
								post=start_location.post	
								@searchresults.push post	
								@matches = @matches + 1
							end
						end
						for stops1 in @stops1
							if !@end_locations.find_by_post_id(stops1.post.id).nil? 
								post= stops1.post
								@searchresults.push post
								@matches = @matches + 1
							end
							if !@stops2.find_by_post_id(stops1.post.id).nil? 
								post= stops1.post
								@searchresults.push post
								@matches = @matches + 1
							end
						end
       @searchresults
    
  else
  
   @searchresults= @posts
   @searchresults
   
  end
      
  end

def myposts

@posts = current_user.posts.paginate(:page => params[:page], :per_page => 10)
end

  def show
    @post = Post.find(params[:id])
    
   	@friends = @post.user.friends.all
   	@start=@post.start
    @stops= @post.stops.all
    @finish= @post.finish

   	
   	
  end

  def new
    @post = Post.new
@post.build_start
    @post.build_finish

    @post.stops.new
  end

  def create
    @post = Post.new(params[:post])
   if current_user
   	@post.user= current_user
   	
    if @post.save
     
          
      redirect_to @post, :alert => "created"
      
      
    else
      render :action => 'new'
    end
    else
    render :action => 'new'
    end
  end

  def edit
    @post = Post.find(params[:id])
  
  end

  def update
    @post = Post.find(params[:id])
    if @post.update_attributes(params[:post])
      redirect_to @post, :notice  => "Successfully updated post."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy if current_user == @post.user 
    redirect_to posts_url, :notice => "Successfully destroyed post."
  end
  
  def authenticate_user
  if !current_user
  redirect_to root_path, class: "alert alert-success", :notice => "You need to sign in before you can make a post"
  end
  end
    
		def facebook
		  
			if current_user
				@graph = Koala::Facebook::API.new(current_user.token)
			end
		end
		def editing
		@post= Post.find(params[:id])
		if current_user == @post.user
		true
		else
	redirect_to root_path
		end
		end
		
		def make_booking
			 @post = Post.find(params[:id])
			 Booking.create(post_id: @post.id, user_id: current_user.id, accepted: false, rejected: false)
			 redirect_to @post
		end
  
end
