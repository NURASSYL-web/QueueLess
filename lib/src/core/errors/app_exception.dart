class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppConfigurationException extends AppException {
  const AppConfigurationException(super.message);
}
