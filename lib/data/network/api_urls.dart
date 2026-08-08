import 'package:nimmys_crm/data/network/env/environment_variable.dart';

class ApiUrls {
  ApiUrls._();

  // Env
  static String get _fetchUrl => EnvironmentVariables.fetchBaseUrl;
  static String get _path => "/api";

  // Base URL
  static String get _baseUrl => "$_fetchUrl$_path";
  static String  baseUrl = _baseUrl;

  // End Point
  static String sendOtpWithPhoneNumber = "$_baseUrl/otpSend/phoneNumber";
  static String login = "$_baseUrl/login";
  static String logout = "$_baseUrl/logout";
  static String profile = "$_baseUrl/profile";


}
