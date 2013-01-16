require 'cgi'
require 'digest/md5'

require 'multi_json'

# OpenSSL and Base64 are required to support signed_request
require 'openssl'
require 'base64'

# include koala modules
require 'koala/http_services'
require 'koala/http_services/net_http_service'
require 'koala/oauth'
require 'koala/graph_api'
require 'koala/graph_batch_api'
require 'koala/batch_operation'
require 'koala/graph_collection'
require 'koala/rest_api'
require 'koala/realtime_updates'
require 'koala/test_users'
require 'koala/http_services'

# add KoalaIO class
require 'koala/uploadable_io'

module Koala

  module Facebook
    # Ruby client library for the Facebook Platform.
    # Copyright 2010-2011 Alex Koppel
    # Contributors: Alex Koppel, Chris Baclig, Rafi Jacoby, and the team at Context Optional
    # http://github.com/arsduo/koala

    class API
      # initialize with an access token
      def initialize(access_token = nil)
        @access_token = access_token
      end
      attr_reader :access_token

      def api(path, args = {}, verb = "get", options = {}, &error_checking_block)
        # Fetches the given path in the Graph API.
        args["access_token"] = @access_token || @app_access_token if @access_token || @app_access_token
        
        # add a leading /
        path = "/#{path}" unless path =~ /^\//

        # make the request via the provided service
        result = Koala.make_request(path, args, verb, options)

        # Check for any 500 errors before parsing the body
        # since we're not guaranteed that the body is valid JSON
        # in the case of a server error
        raise APIError.new({"type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}"}) if result.status >= 500

        # parse the body as JSON and run it through the error checker (if provided)
        # Note: Facebook sometimes sends results like "true" and "false", which aren't strictly objects
        # and cause MultiJson.decode to fail -- so we account for that by wrapping the result in []
        body = MultiJson.decode("[#{result.body.to_s}]")[0]
        yield body if error_checking_block

        # if we want a component other than the body (e.g. redirect header for images), return that
        options[:http_component] ? result.send(options[:http_component]) : body
      end
    end

    # APIs
    
    class GraphAPI < API
      include GraphAPIMethods
    end
    
    class GraphBatchAPI < GraphAPI
      include GraphBatchAPIMethods      
    end
        
    class RestAPI < API
      include RestAPIMethods
    end

    class GraphAndRestAPI < API
      include GraphAPIMethods
      include RestAPIMethods
    end

    class RealtimeUpdates < API
      include RealtimeUpdateMethods
    end

    class TestUsers < API
      include TestUserMethods
      # make the Graph API accessible in case someone wants to make other calls to interact with their users
      attr_reader :graph_api
    end

    # Errors

    class APIError < StandardError
      attr_accessor :fb_error_type
      def initialize(details = {})
        self.fb_error_type = details["type"]
        super("#{fb_error_type}: #{details["message"]}")
      end
    end
  end

  class KoalaError < StandardError; end

  # Make an api request using the provided api service or one passed by the caller
  def self.make_request(path, args, verb, options = {})
    http_service = options.delete(:http_service) || Koala.http_service
    options = options.merge(:use_ssl => true) if @always_use_ssl
    http_service.make_request(path, args, verb, options)
  end

  # finally, set up the http service Koala methods used to make requests
  # you can use your own (for HTTParty, etc.) by calling Koala.http_service = YourModule
  class << self
    attr_accessor :http_service
    attr_accessor :always_use_ssl
    attr_accessor :base_http_service
  end
  Koala.base_http_service = NetHTTPService

  # by default, try requiring Typhoeus -- if that works, use it
  # if you have Typheous and don't want to use it (or want another service),
  # you can run Koala.http_service = NetHTTPService (or MyHTTPService)
  begin
    require 'koala/http_services/typhoeus_service'
    Koala.http_service = TyphoeusService
  rescue LoadError
    Koala.http_service = Koala.base_http_service
  end
end
