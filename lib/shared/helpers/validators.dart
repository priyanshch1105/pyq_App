class Validators {
  const Validators._();

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';
    if (!input.contains('@')) return 'Enter a valid email';
    return null;
  }
}
