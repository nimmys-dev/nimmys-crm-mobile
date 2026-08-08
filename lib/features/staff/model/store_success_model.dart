/// `GET /api/branches` response — the shops a staff member can be assigned to.
///
/// The endpoint is named "branches" but its payload is the shop record, which is
/// why `id` is what Create Staff wants for `shop_id`.
class StoreModelSuccess {
    StoreModelSuccess({
        required this.status,
        required this.statusCode,
        required this.message,
        required this.data,
    });

    final bool? status;
    final int? statusCode;
    final String? message;
    final List<StoreResponseData> data;

    factory StoreModelSuccess.fromJson(Map<String, dynamic> json){
        return StoreModelSuccess(
            status: json["status"],
            statusCode: json["status_code"],
            message: json["message"],
            data: json["data"] == null ? [] : List<StoreResponseData>.from(json["data"]!.map((x) => StoreResponseData.fromJson(x))),
        );
    }

    /// The only branches worth offering on Staff Creation: assigning someone to a
    /// closed shop is a data error the API would have to reject anyway.
    ///
    /// A branch with no `id` is dropped too — `shop_id` is what the create call
    /// actually sends, so a nameless-to-the-API row cannot be selected.
    List<StoreResponseData> get activeBranches =>
        data.where((branch) => branch.isActive && branch.id != null).toList();

}

class StoreResponseData {
    StoreResponseData({
        required this.id,
        required this.name,
        required this.status,
    });

    final int? id;
    final String? name;
    final String? status;

    factory StoreResponseData.fromJson(Map<String, dynamic> json){
        return StoreResponseData(
            id: _asInt(json["id"]),
            name: json["name"],
            status: json["status"],
        );
    }

    /// Ids arrive as numbers today, but Laravel serialises them as strings under
    /// some driver/column combinations — parsing both keeps a server config
    /// change from turning into a cast crash on the phone.
    static int? _asInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    bool get isActive => status?.toLowerCase() == 'active';

}
