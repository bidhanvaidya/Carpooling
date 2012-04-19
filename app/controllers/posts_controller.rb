class PostsController < ApplicationController
before_filter :authenticate_user, :except=> [:show, :index]
  def index
    @posts = Post.all
      
  end

def search
@posts = Post.all
if params[:start].present? && params[:finish].present?
      #@post_with_location= Post.find_by_sql("select * from posts inner join locations on locations.post_id=posts.id")
      @start_locations= Start.near(params[:start], 1, :order => :distance).includes(:post)
  		@end_locations= Finish.near(params[:finish], 1, :order => :distance).includes(:post)
    		@stops1= Stop.near(params[:start], 1, :order => :distance).includes(:post)
        @stops2= Stop.near(params[:finish], 1, :order => :distance).includes(:post)
  else
    @start_locations = nil
  end
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
   
   	@post.user= current_user
    if @post.save
     
          
      redirect_to @post, :alert => "created"
      
      
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
  redirect_to root_path, :notice => "You need to sign in before you can make a post"
  end
  end
  
end
