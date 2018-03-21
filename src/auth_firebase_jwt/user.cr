module Auth::Strategies::Firebase
  class FirebaseUser
    JSON.mapping(
      user_id: String,
      auth_time: {converter: Time::EpochConverter, type: Time},
      display_name: (String | Nil),
      email: (String | Nil),
      email_verified: (Bool | Nil),
      phone_number: (String | Nil),
    )
  end
end
