import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  AppVersionService._();

  static final AppVersionService instance = AppVersionService._();

  String? _version;

  Future<String> getVersion() async {
    if (_version != null) {
      return _version!;
    }

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    _version = packageInfo.version;

    return _version!;
  }

  Future<String> getFullVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }
}