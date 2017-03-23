module NeverBounce
  class Error < StandardError; end
  class AccessTokenExpired < Error; end
  class ApiBulkAccessRestricted < Error; end
  class ApiError < Error; end
  class AuthError < Error; end
  class ResponseError < Error; end
  class RequestError < Error; end
  class SourceNotDefined < Error; end
  class DownloadError < Error; end
  class UnknownEmail < Error; end
end
