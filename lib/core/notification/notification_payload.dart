import '../utils/custom_log.dart';

class NotificationPayload {
  String? route;
  String? eventType;
  String? mode;
  String? toUser;
  String? osType;
  String? title;
  String? body;
  String? screen;
  NotificationData? notificationData;
  String? userType;
  String? loadSeriesId;

  NotificationPayload({this.route, this.eventType, this.mode, this.toUser,
    this.osType, this.title, this.body, this.screen, this.notificationData,this.userType,this.loadSeriesId});


  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    CustomLog.debug(NotificationPayload, "json is $json");

    return NotificationPayload(
        route: json['route'],
        loadSeriesId:json['id'],
        eventType: json['eventType'],
        mode: json['mode'],
        title: json['title'],
        body: json['body'],
        screen: json['screen'],
        osType: json['os_type'],
        userType:json['user_type'],
        toUser: json['to_user'],
        notificationData:json['data']!=null ?  NotificationData.fromJson(json['data']):null
    );
  }

  Map<String, dynamic> toJson() {
    return {'route': route, 'eventType': eventType, 'mode': mode};
  }


}

class NotificationData{
  String? id;
  String? userType;

  NotificationData({
    this.id,
    this.userType
});

  NotificationData.fromJson(Map<String,dynamic> json){
    id=json['id'];
    userType=json['user_type'];
  }
}
