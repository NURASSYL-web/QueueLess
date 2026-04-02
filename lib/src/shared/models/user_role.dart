enum UserRole {
  regular('user', 'User'),
  business('business', 'Business');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.regular,
    );
  }
}
