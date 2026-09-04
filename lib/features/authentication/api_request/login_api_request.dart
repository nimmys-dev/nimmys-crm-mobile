import 'package:nimmys_crm/data/model/serializable.dart';

class LoginApiRequest extends Serializable{
  LoginApiRequest({
    required this.email,
    required this.password,
    required this.fcm_token,
  });

  final String email;
  final String password;
  final String fcm_token;


  @override
  Map<String, dynamic> toJson() => {
    "email": email,
    "password": password,
    "fcm_token": fcm_token,
  };

}
