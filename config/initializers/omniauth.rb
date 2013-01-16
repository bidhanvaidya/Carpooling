OmniAuth.config.logger = Rails.logger
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '414998911867511', '29ad937c5e4f060398af36cde9e60660',:display => 'popup', :scope => 'user_work_history,email,user_education_history,user_interests,user_hometown,user_location,user_actions.music'
end

