import 'dart:io';

import 'package:nimmys_crm/data/model/serializable.dart';

/// `POST /api/update-staff/{id}` request.
///
/// A separate class from [CreateStaffApiRequest] rather than a shared base,
/// matching this project's one-flat-class-per-endpoint convention (see
/// `LoginApiRequest`) — and for a real reason, not just convention: on create,
/// [password] is required and the type system says so; on edit, a blank
/// password/confirmation pair is a normal answer meaning "keep the current
/// one", so the fields have to be optional here in a way create's must not be.
///
/// ASSUMPTION — password optionality on update was not verified against the
/// live API; the only confirmed example sent a fresh password on every edit.
/// Forcing a re-entered password on every profile tweak would be unusual
/// enough UX that this project's edit form treats it as optional and omits
/// both fields when left blank, the same way every other optional field on
/// this form is dropped rather than sent empty (see [toFormFields]). If the
/// backend's `password` rule turns out to require the field outright, this is
/// the one place that changes.
///
/// ASSUMPTION — [photo] is likewise omitted, not resent, when the user did not
/// pick a new one; standard for an optional file-upload field on a Laravel
/// update route, but not something the one available example (which did
/// attach a new photo) rules out either way.
class UpdateStaffApiRequest extends Serializable {
  UpdateStaffApiRequest({
    required this.name,
    required this.phone,
    required this.shopId,
    required this.role,
    required this.joiningDate,
    required this.salary,
    required this.incrementNotification,
    required this.leadModuleAccess,
    this.password,
    this.passwordConfirmation,
    this.email,
    this.alternatePhone,
    this.incrementDate,
    this.incrementAmount,
    this.description,
    this.photo,
    this.status = activeStatus,
  });

  static const String activeStatus = 'active';

  final String name;
  final String phone;

  /// Both null (or both blank) means "leave the password unchanged" — the
  /// screen only builds this with values when the user actually typed one.
  final String? password;
  final String? passwordConfirmation;

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

  /// Sent as the `photo` part. Null means "don't touch the existing photo" —
  /// handed to `ApiService.multipart` separately from [toFormFields] because a
  /// file is not a form field.
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
  /// Optional fields left blank are dropped rather than sent empty: Laravel's
  /// `nullable|date_format:d-m-Y` rule rejects `""`, so an untouched increment
  /// date would fail validation for a field the user never filled in. The
  /// password pair follows the same rule, which is what makes leaving both
  /// blank mean "no change" rather than "clear the password".
  Map<String, String> toFormFields() {
    final Map<String, String> fields = <String, String>{
      "name": name,
      "phone": phone,
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

    putIfPresent("password", password);
    putIfPresent("password_confirmation", passwordConfirmation);
    putIfPresent("email", email);
    putIfPresent("alternate_phone", alternatePhone);
    putIfPresent("increment_date", incrementDate);
    putIfPresent("increment_amount", incrementAmount);
    putIfPresent("description", description);

    return fields;
  }
}
