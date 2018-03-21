# Firebase JWT Auth Strategy

`randomstate/auth-firebase-jwt` provides a Firebase JWT strategy for `randomstate/auth`

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  auth_firebase_jwt:
    github: randomstate/auth-firebase-jwt
```

## Usage

```crystal
require "auth_firebase_jwt"
```

### Instantiation

```crystal
strategy = Auth::Strategies::Firebase::JWT.new "{PROJECT_ID}" # PROJECT_ID is your Firebase Project ID

manager = Auth::Manager.new
manager.use :jwt, strategy
```

### Converting FirebaseUser to your User object

```crystal
strategy.when_converting do | firebase_user |
  my_user = User.new
  my_user.id = firebase_user.user_id
  my_user.email = firebase_user.email

  my_user # must return your own user object
end
```

The following properties are available on the FirebaseUser object

```crystal
  user_id: String,
  auth_time: Time,
  display_name: (String | Nil),
  email: (String | Nil),
  email_verified: (Bool | Nil),
  phone_number: (String | Nil),
```

## Contributing

1. Fork it ( https://github.com/randomstate/auth-firebase-jwt/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [cimrie](https://github.com/cimrie) Connor Imrie - creator, maintainer
