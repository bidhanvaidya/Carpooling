begin
  require 'bundler/setup'
rescue LoadError
  puts 'Although not required, bundler is recommended for running the tests.'
end

# load the libraries
require 'koala'

# load testing data libraries
require 'support/live_testing_data_helper'
require 'support/json_testing_fix' # ensure consistent to_json behavior
require 'support/mock_http_service'
require 'support/rest_api_shared_examples'
require 'support/graph_api_shared_examples'
require 'support/uploadable_io_shared_examples'
require 'support/setup_mocks_or_live'

BEACH_BALL_PATH = File.join(File.dirname(__FILE__), "fixtures", "beach.jpg")