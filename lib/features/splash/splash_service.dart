import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/authentication/repository/user_information_repository.dart';

class SplashService{
  final UserInformationRepository _userInformationRepository;
  SplashService(this._userInformationRepository);

  Future<Result<bool>> checkIsUserLogin() async {
    String? userId = await _userInformationRepository.getUserID();
    if(userId != null){
      return const Success(true);
    }else{
      return Error(UnauthenticatedError());
    }
  }


}