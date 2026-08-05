import 'package:nimmys_crm/data/model/serializable.dart';

class LoginApiRequest extends Serializable{
  LoginApiRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;


  @override
  Map<String, dynamic> toJson() => {
    "email": email,
    "password": password,
  };

}
