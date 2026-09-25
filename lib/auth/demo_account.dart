/// A built-in demo login, so the screens after sign-in can be reached before
/// real authentication exists. Remove it once Firebase Auth is set up.
class DemoAccount {
  DemoAccount._();

  static const String email = 'demo@foodlink.org';
  static const String password = 'foodlink123';

  /// Whether [email] and [password] are the demo login (email ignores case
  /// and surrounding spaces).
  static bool matches(String email, String password) =>
      email.trim().toLowerCase() == DemoAccount.email &&
      password == DemoAccount.password;
}
