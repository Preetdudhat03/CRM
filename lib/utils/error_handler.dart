class ErrorHandler {
  static String formatError(Object error) {
    String errorMsg = error.toString();
    
    // Check for network related exceptions
    final lowerCaseError = errorMsg.toLowerCase();
    if (lowerCaseError.contains('socketexception') || 
        lowerCaseError.contains('clientexception') ||
        lowerCaseError.contains('failed host lookup') ||
        lowerCaseError.contains('connection refused')) {
      return 'Offline or couldn\'t connect to internet';
    }

    // Clean up generic exception string formatting
    if (errorMsg.startsWith('Exception: ')) {
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
    }

    return errorMsg;
  }
}
