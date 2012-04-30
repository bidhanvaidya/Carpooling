class ProfilesController < ApplicationController
def index
  @user= User.find(params[:user_id]).profile
  @page = FbGraph::Page.fetch(@user.user.uid)
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
end
