import 'dart:io';

import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/profile/model/company_details_model.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';

class ProfileService {
  final ApiService _apiService;
  ProfileService(this._apiService);

  // Profile Service
  //
  // GET /api/profile. No parameters — the bearer token ApiService attaches
  // identifies the staff member, so this always returns the signed-in user.
  Future<Result<ProfileSuccessModel>> getProfile() async {
    try {
      final url = ApiUrls.profile;
      final result = await _apiService.get(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<ProfileSuccessModel>(
          result.value,
          (json) => ProfileSuccessModel.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // GET /api/company profile. No parameters — the bearer token ApiService attaches
  // identifies the staff member, so this always returns the signed-in user.
  Future<Result<CompanyProfileResponse>> getCompanyProfile() async {
    try {
      final url = ApiUrls.companyProfile;
      final result = await _apiService.get(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<CompanyProfileResponse>(
          result.value,
          (json) => CompanyProfileResponse.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

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
    final fields = {
      'name': name,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'email': email,
    };

    // Use the multipart method from ApiService
    final result = await _apiService.multipart(
      ApiUrls.updateCompanyProfile,
      logo, // files parameter, can be null
      fields: fields,
      pathName: 'logo', // the field name for the file
    );

    if (result is Success) {
      return await _apiService.getResponseStatus<CompanyProfileResponse>(
        result.value,
        (json) => CompanyProfileResponse.fromJson(json),
      );
    } else if (result is Error) {
      return Error(result.type);
    } else {
      return Error(GenericError());
    }
  } catch (e) {
    return Error(DeserializationError());
  }
}}
