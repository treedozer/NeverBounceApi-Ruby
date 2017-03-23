module NeverBounce
  class Single
    attr_accessor :master

    def initialize(master)
      @master = master
    end

    # Makes verification request
    # Returns VerifiedEmail instance
    def verify(email)
      VerifiedEmail.new(@master.call('/v3/single', {:email => email}))
    end
  end
  class VerifiedEmail
    attr_reader :success, :result, :result_details, :execution_time, :text_result, :response

    def initialize(response)
      @response       = JSON.parse(response.parsed_response)
      @success        = @response['success']
      @result         = @response['result']
      @result_details = @response['result_details']
      @execution_time = @response['execution_time']
      @text_codes     = %w(valid invalid disposable catchall unknown)
      @text_result    = @text_codes[@result]
    end

    # Returns numeric result code
    def get_result_code
      @result
    end

    # Returns textual result code
    def get_result_text_code
      @text_codes[@result]
    end

    # Returns true if result is in the specified codes
    # Accepts either array of result codes or single result code
    def is(codes)
      if codes.kind_of?(Array)
        codes.include?(@result)
      else
        codes === @result
      end
    end

    # Returns true if result is NOT in the specified codes
    # Accepts either array of result codes or single result code
    def not(codes)
      if codes.kind_of?(Array)
        !codes.include?(@result)
      else
        codes != @result
      end
    end

    alias getResultCode get_result_code
    alias getResultTextCode get_result_text_code

  end
end
