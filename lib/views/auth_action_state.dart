class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  AuthActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
    );
  }
}
