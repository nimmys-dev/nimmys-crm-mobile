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
            id: json["id"],
            name: json["name"],
            status: json["status"],
        );
    }

}
