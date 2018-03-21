require "./spec_helper"
# require "./helpers/*"
require "http"

include Auth

req = HTTP::Request.new("GET", "/api")
token = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImRhNWZiMGJkZTJlMzUwMmZkZTE1YzAwMWE0MWIxYzkxNDc4MTI0NzYifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdGF4ZmluZGVyLWFmNTA5IiwiYXVkIjoidGF4ZmluZGVyLWFmNTA5IiwiYXV0aF90aW1lIjoxNTIwNzc3MzMyLCJ1c2VyX2lkIjoiRkVrem1ueTdTZ2V6YXdjM25ZQ2ozdWp2dGltMiIsInN1YiI6IkZFa3ptbnk3U2dlemF3YzNuWUNqM3VqdnRpbTIiLCJpYXQiOjE1MjE2MzA3MDksImV4cCI6MTUyMTYzNDMwOSwiZW1haWwiOiJjb25ub3JAcmFuZG9tc3RhdGUuY28udWsiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsiY29ubm9yQHJhbmRvbXN0YXRlLmNvLnVrIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifX0.XDB1x_CMnGnuwttU7ZdoB07MuoiCfgd8kluBzKBhIsaPnPcbxEwBdEN0RYWpJqXkW34_2Q26O2isIo9X2cf_r1EZqaDO1jsUlHx7J6gRKSNW9UCT0va63PiAzZevkfN6t0ttpe23UhwtglVDbbFqsoXXnRYRoQH_YQJZZ3VCgqoamRx5gX8mLZFBT2EaoZ3JP1i6WzkhV2W298Ugpamcv0ENHJ14ul7fXnzCYtGvPDtPz63JSD4WgUhQnN6332LCrvnfYKUbyiVuYCE1fyHSb3X2G-gXLlHUWr48AWOpEoa8nGq3kaiymnt8gpRN_zityy_XBSJminYUJTBh1B5nTA"
req.headers["Authorization"] = "Bearer #{token}"
resp = HTTP::Server::Response.new(IO::Memory.new)
context = HTTP::Server::Context.new(req, resp)

Auth.define_user_class ExampleUser
Auth.can_use Strategies::Firebase::JWT

describe Auth::Strategies::Firebase::JWT do
  it "can fetch a token from an authorization header" do
    jwt_strategy = Strategies::Firebase::JWT.new "1234"
    jwt_strategy.get_token(context).class.should eq JWT::Token
  end

  it "can validate and verify a token" do
    jwt_strategy = Strategies::Firebase::JWT.new "1234"
    jwt_strategy.current_time = Time.new(2018, 3, 21, 11, 15)
    jwt = jwt_strategy.get_token(context)

    if jwt.nil?
      jwt.should_not be_nil
      next
    end

    is_valid = jwt_strategy.validate_token(jwt)
    is_verified = jwt_strategy.verify_token(jwt)

    is_valid.should be_false   # wasn't issued with that project ID
    is_verified.should be_true # signature is a google one
  end

  it "can provide user details from a token" do
    jwt_strategy = Strategies::Firebase::JWT.new "taxfinder-af509"
    jwt_strategy.current_time = Time.new(2018, 3, 21, 11, 15)

    user = jwt_strategy.attempt(context)

    user.should_not be_nil

    if user.nil?
      next
    end

    user.email.should eq "connor@randomstate.co.uk"
  end

  it "can convert firebase user to custom user" do
    jwt_strategy = Strategies::Firebase::JWT.new "taxfinder-af509"

    manager = Auth::Manager.new
    manager.use_sessions = false

    manager.use :jwt, jwt_strategy

    jwt_strategy.when_converting do |firebase_user|
      user = ExampleUser.new
      user.email = firebase_user.email

      user
    end

    user = manager.authenticate(:jwt, context)

    user.should_not be_nil

    if user.nil?
      next
    end

    user.class.should_not eq Strategies::Firebase::FirebaseUser
    user.email.should eq "connor@randomstate.co.uk"
  end
end
