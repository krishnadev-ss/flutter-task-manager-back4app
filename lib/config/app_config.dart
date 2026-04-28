/// Back4App / Parse Server credentials.
///
/// 1. Go to https://www.back4app.com/ and create a free account.
/// 2. Create a new app.
/// 3. Navigate to App Settings → Security & Keys.
/// 4. Copy your Application ID, Client Key, and use the default Server URL below.
/// 5. Replace the placeholder strings with your real credentials and run the app.
///
/// ⚠️  Never commit real credentials to a public repository.
///    Add lib/config/app_config.dart.local to .gitignore for team projects
///    and inject values via CI environment variables.
class AppConfig {
  AppConfig._();

  static const String applicationId = 'nXK2UGoSRlJjHHq5nWZAgdJ2Ah7lkloDzvHtFZgq';
  static const String clientKey = 'NI1uzC2B0vQWIAKehem5fgyqArUmpM0nNtFaOtbv';
  static const String serverUrl = 'https://parseapi.back4app.com';

  /// Application display name
  static const String appName = 'Task Manager';
}
