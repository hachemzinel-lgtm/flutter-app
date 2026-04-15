class UserRepositoryException implements Exception {
  const UserRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class UserRepository {
  Future<void> createUserDocument(String userId, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getUserDocument(String userId);
  Future<void> updateUserDocument(String userId, Map<String, dynamic> data);
  Future<bool> userDocumentExists(String userId);
}
