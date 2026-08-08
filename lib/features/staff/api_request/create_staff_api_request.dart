import 'dart:io';

import 'package:nimmys_crm/data/model/serializable.dart';

/// `POST /api/create-staff` request.
///
/// The call is multipart because of [photo], so every value ends up on the wire
/// as a string — [toFormFields] does that conversion in one place instead of
/// leaving `'1'` / `'0'` literals scattered through the screen.
class CreateStaffApiRequest extends Serializable {
  CreateStaffApiRequest({
    required this.name,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.shopId,
    required this.role,
    required this.joiningDate,
    required this.salary,
    required this.incrementNotification,
    required this.leadModuleAccess,
    this.email,
    this.alternatePhone,
    this.incrementDate,
    this.incrementAmount,
    this.description,
    this.photo,
    this.status = activeStatus,
  });

  /// Staff are created enabled — the screen has no "create as inactive" option.
  static const String activeStatus = 'active';

  final String name;
  final String phone;
  final String password;
  final String passwordConfirmation;

  /// The branch id from `GET /api/branches`, never the branch name.
  final int shopId;
  final String role;

  /// Both dates are `dd-MM-yyyy` — see `DateTimeHelper.getApiDateFormat`.
  final String joiningDate;
  final String salary;
  final bool incrementNotification;
  final bool leadModuleAccess;
  final String? email;
  final String? alternatePhone;
  final String? incrementDate;
  final String? incrementAmount;
  final String? description;

  /// Sent as the `photo` part. Handed to `ApiService.multipart` separately from
  /// [toFormFields] because a file is not a form field.
  final File? photo;
  final String status;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "name": name,
    "email": email,
    "phone": phone,
    "password": password,
    "password_confirmation": passwordConfirmation,
    "shop_id": shopId,
    "role": role,
    "joining_date": joiningDate,
    "salary": salary,
    "increment_date": incrementDate,
    "increment_amount": incrementAmount,
    "increment_notification": incrementNotification,
    "lead_module_access": leadModuleAccess,
    "description": description,
    "alternate_phone": alternatePhone,
    "status": status,
  };

  /// Multipart body for `ApiService.multipart`.
  ///
  /// Optional fields that were left blank are dropped rather than sent empty:
  /// Laravel's `nullable|date_format:d-m-Y` rule rejects `""`, so an untouched
  /// increment date would fail validation for a field the user never filled in.
  /// The two toggles are always present — `0` is a real answer, not a blank.
  Map<String, String> toFormFields() {
    final Map<String, String> fields = <String, String>{
      "name": name,
      "phone": phone,
      "password": password,
      "password_confirmation": passwordConfirmation,
      "shop_id": shopId.toString(),
      "role": role,
      "joining_date": joiningDate,
      "salary": salary,
      "increment_notification": incrementNotification ? "1" : "0",
      "lead_module_access": leadModuleAccess ? "1" : "0",
      "status": status,
    };

    void putIfPresent(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        fields[key] = value.trim();
      }
    }

    putIfPresent("email", email);
    putIfPresent("alternate_phone", alternatePhone);
    putIfPresent("increment_date", incrementDate);
    putIfPresent("increment_amount", incrementAmount);
    putIfPresent("description", description);

    return fields;
  }
}
