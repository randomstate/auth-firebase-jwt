require "jwt"
require "./user.cr"

include JWT
include Auth

module Auth::Strategies::Firebase
  class FirebaseJWTError < Exception
  end

  class JWT < Strategy(FirebaseUser)
    GOOGLE_PUBLIC_KEY_SOURCE_URL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

    property clock : Proc(Time) = ->{ Time.now }

    def initialize(@project_id : String)
    end

    def attempt(context : HTTP::Server::Context) : (FirebaseUser | Nil)
      token = get_token context

      if token.nil?
        return
      end

      is_valid = validate_token token
      is_verified = verify_token token

      if !(is_valid && is_verified)
        return
      end

      # Return new firebase user because it is valid
      FirebaseUser.from_json Base64.decode_string(token.payload64)
    end

    def get_token(context)
      if !context.request.headers.has_key? "Authorization"
        return nil
      end

      authorization = context.request.headers["Authorization"]
      matches = authorization.match(/Bearer\s(?'token'.*)/)
      # get from authorization header bearer token
      token = matches["token"] unless matches.nil?

      if token.nil?
        return
      end

      return ::JWT::Token.decode(token)
    end

    def validate_token(token)
      validator = ::JWT::Validator.new @clock.call
      validator.issuer = "https://securetoken.google.com/#{@project_id}"
      validator.audience = @project_id

      validator.custom "kid", :header do |kid|
        next(!kid.nil?)
      end

      validator.validate(token)
    end

    def verify_token(token)
      x509 = get_cert_by_id token.headers["kid"].to_s
      ::JWT::Verifier::RSA.verify(token, x509.public_key, ::JWT::Algorithm::RS256)
    end

    def get_cert_by_id(id)
      context = OpenSSL::SSL::Context::Client.insecure
      response = HTTP::Client.get GOOGLE_PUBLIC_KEY_SOURCE_URL, tls: context
      certs = JSON.parse(response.body)

      cert_pem = certs[id].to_s.chomp
      OpenSSL::X509::Certificate.new cert_pem
    end
  end
end
