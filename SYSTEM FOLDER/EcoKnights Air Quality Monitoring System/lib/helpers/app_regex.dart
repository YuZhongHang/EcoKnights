class AppRegex {
  static bool isEmailValid(String email) {
    return RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
        .hasMatch(email);
  }

  /// Accepts:
  /// - Old rule: at least 6 characters (for existing accounts)
  /// - New rule: at least 8 characters + 1 special character (for new accounts)
  static bool isPasswordValid(String password) {
    final oldRule = RegExp(r'^.{6,}$'); 
    final newRule = RegExp(r'^(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$');
    return oldRule.hasMatch(password) || newRule.hasMatch(password);
  }

  /// Checks if string contains at least 1 special character
  static bool hasSpecialCharacter(String text) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
  }
}
