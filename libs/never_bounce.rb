require 'httparty'
require 'json'

require __FILE__ + '/../never_bounce/errors'
require __FILE__ + '/../never_bounce/single'
require __FILE__ + '/../never_bounce/list'

module NeverBounce

  VERSION = '0.1.5'.freeze

  class API
    include HTTParty
    attr_accessor :host, :path, :api_key, :api_secret, :access_token, :options

    alias :apiKey :api_key
    alias :apiKey= :api_key=
    alias :apiSecret :api_secret
    alias :apiSecret= :api_secret=
    alias :accessToken :access_token
    alias :accessToken= :access_token=

    base_uri 'https://api.neverbounce.com'

    def initialize(api_key, api_secret)
      @api_key = api_key
      @api_secret = api_secret
      @access_token = nil
      @options = {
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'User-Agent' => 'NeverBounce-Ruby/' + VERSION
        }
      }

      raise AuthError, 'You must provide a NeverBounce API key' unless @api_key
      raise AuthError, 'You must provide a NeverBounce API secret key' unless @api_secret
    end

    # Call api endpoint
    def call(endpoint, body)
      begin
        opts = body.merge(access_token: get_access_token)
        request(endpoint, body: opts)
        # If access token is expired we'll retry the request
      rescue AccessTokenExpired
        @access_token = nil
        opts = body.merge(access_token: get_access_token)
        request(endpoint, body: opts)
      end
    end

    # Makes the actual api request
    def request(endpoint, params)
      opts = options.merge(params)
      response = self.class.post(endpoint, opts)

      # Handle non successful requests
      if response['success'] === false
        if response['msg'] === 'Authentication failed'
          raise AccessTokenExpired
        elsif response['error_code'] === 2
          raise ApiBulkAccessRestricted, response['msg'] || response['error_msg']
        end

        raise RequestError, 'We were unable to complete your request. ',
              'The following information was supplied: ',
              "#{response['msg'] || response['error_msg']}\n\n",
              '(Request error)'
      end
      response
    end

    # Lets get the access token
    # If we don't have one available
    # already we'll request a new one
    def get_access_token
      # Get existing access token if available
      return @access_token unless @access_token.nil?

      # Perform request if no existing access token
      params = {
        body: {
          grant_type:  'client_credentials',
          scope:       'basic user'
        },
        basic_auth: {
          username:  @api_key,
          password:  @api_secret
        }
      }
      response = request('/v3/access_token', params)

      if response['error'] != nil
        raise AuthError,	'We were unable to complete your request. ',
              'The following information was supplied: ',
              "#{response['error_description']}\n\n",
              "(Request error [#{response['error']}])"
      end

      @access_token = response['access_token']
    end

    alias getAccessToken get_access_token

    # Initializes the single method
    def single
      Single.new(self)
    end

    # Initializes the list method
    def list
      List.new(self)
    end
  end
end
