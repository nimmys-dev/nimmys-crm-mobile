import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/profile/model/company_details_model.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';
import 'package:nimmys_crm/features/profile/service/profile_service.dart';
import 'dart:io'; 

class ProfileRepository {
  final ProfileService _service;
  ProfileRepository(this._service);

  // Profile Repo
  Future<Result<ProfileSuccessModel>> getProfile() async {
    try {
      return await _service.getProfile();
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

  // Company Profile Repo
  Future<Result<CompanyProfileResponse>> getCompanyProfile() async {
    try {
      return await _service.getCompanyProfile();
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

  // Update Company Profile Repo
  Future<Result<CompanyProfileResponse>> updateCompanyProfile({
    required String name,
    required String addressLine,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String phone,
    required String email,
    File? logo,
  }) async {
    try {
      return await _service.updateCompanyProfile(
        name: name,
        addressLine: addressLine,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        phone: phone,
        email: email,
        logo: logo,
      );
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }
}
