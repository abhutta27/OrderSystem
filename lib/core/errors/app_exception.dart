/// Base application exception
class AppException implements Exception {
  final String message;
  final dynamic cause;

  AppException(this.message, [this.cause]);

  @override
  String toString() => message;
}

/// Thrown when a store cannot be found by store_code or store_id
class StoreNotFoundException extends AppException {
  final String query;

  StoreNotFoundException(this.query)
      : super('No restaurant or store was found matching "$query".');
}

/// Thrown when the store license has been remotely suspended or deactivated
class StoreSuspendedException extends AppException {
  final String storeName;

  StoreSuspendedException(this.storeName)
      : super(
          'Store "$storeName" is currently inactive or suspended by administrator. Please contact billing/support.',
        );
}

/// Thrown when network or Supabase operation fails
class DatabaseOperationException extends AppException {
  DatabaseOperationException(super.message, [super.cause]);
}
