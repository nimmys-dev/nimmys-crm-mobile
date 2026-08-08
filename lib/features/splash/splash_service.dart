import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/authentication/repository/user_information_repository.dart';

class SplashService{
  final UserInformationRepository _userInformationRepository;
  SplashService(this._userInformationRepository);

  // The token, not the user id: it is what every authenticated request carries,
  // so its absence — or an empty string left behind by a half-written session —
  // is the only honest definition of "not signed in".
  Future<Result<bool>> checkIsUserLogin() async {
    String? token = await _userInformationRepository.getUserToken();
    if(token != null && token.isNotEmpty){
      return const Success(true);
    }else{
      return Error(UnauthenticatedError());
    }
  }


}