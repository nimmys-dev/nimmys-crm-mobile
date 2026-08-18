import 'package:nimmys_crm/data/network/env/environment_variable.dart';

class ApiUrls {
  ApiUrls._();

  // Env
  static String get _fetchUrl => EnvironmentVariables.fetchBaseUrl;
  static String get _path => "/api";

  // Base URL
  static String get _baseUrl => "$_fetchUrl$_path";
  static String baseUrl = _baseUrl;

  // End Point
  static String sendOtpWithPhoneNumber = "$_baseUrl/otpSend/phoneNumber";
  static String login = "$_baseUrl/login";
  static String logout = "$_baseUrl/logout";
  static String profile = "$_baseUrl/profile";
  static String branches = "$_baseUrl/branches";
  static String userRoles = "$_baseUrl/user-roles";
  static String createStaff = "$_baseUrl/create-staff";
  static String staffList = "$_baseUrl/staff";
  static String viewStaff(int id) => "$_baseUrl/view-staff/$id";
  static String updateStaff(int id) => "$_baseUrl/update-staff/$id";
  static String deleteStaff(int id) => "$_baseUrl/delete-staff/$id";
  static String createLead = "$_baseUrl/create-leads";
  static String leadAssignees = "$_baseUrl/lead-assignees";
  static String leads = "$_baseUrl/leads";
  static String viewLead(int id) => "$_baseUrl/view-lead/$id";
  static String updateLead(int id) => "$_baseUrl/update-lead/$id";
}
