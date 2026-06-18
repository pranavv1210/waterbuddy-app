import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'production');

  static Future<void> initialize() async {
    String envFile;
    switch (flavor) {
      case 'development':
      case 'dev':
        envFile = '.env.dev';
        break;
      case 'staging':
      case 'stg':
        envFile = '.env.staging';
        break;
      default:
        envFile = '.env.production';
    }
    await dotenv.load(fileName: envFile);
  }

  static String get appName => dotenv.get('APP_NAME', fallback: 'WaterBuddy');
  static String get googleMapsApiKey => dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
  static String get razorpayKeyId => dotenv.get('RAZORPAY_KEY_ID', fallback: '');

  static List<String> get adminUids {
    final raw = dotenv.get('ADMIN_UIDS', fallback: '');
    return raw.split(',').map((uid) => uid.trim()).where((uid) => uid.isNotEmpty).toList();
  }

  static bool get logVerbose => flavor != 'production';
}
