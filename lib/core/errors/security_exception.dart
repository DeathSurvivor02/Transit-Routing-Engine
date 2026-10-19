/// Exception thrown when cryptographic, database integrity, or tamper detection fails.
class SecurityException implements Exception {
  final String message;
  final dynamic cause;

  const SecurityException(this.message, [this.cause]);

  @override
  String toString() => 'SecurityException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}
