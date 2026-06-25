class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }
}
