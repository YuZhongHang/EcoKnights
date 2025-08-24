// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'auth_cubit.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class IsNewUser extends AuthState {
  final GoogleSignInAccount googleUser;
  final OAuthCredential credential;
  
  IsNewUser({
    required this.googleUser,
    required this.credential,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IsNewUser && 
           other.googleUser == googleUser && 
           other.credential == credential;
  }

  @override
  int get hashCode => googleUser.hashCode ^ credential.hashCode;
}

class ResetPasswordSent extends AuthState {}

class UserNotVerified extends AuthState {}

class UserSignedOut extends AuthState {}

// FIXED: Added user parameter to match cubit usage
class UserSignIn extends AuthState {
  final UserModel user;

  UserSignIn({required this.user});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSignIn && other.user == user;
  }

  @override
  int get hashCode => user.hashCode;
}

class UserSingupAndLinkedWithGoogle extends AuthState {}

class UserSingupButNotVerified extends AuthState {}

// FIXED: Added user parameter to match cubit usage
class AdminSignIn extends AuthState {
  final UserModel user;

  AdminSignIn({required this.user});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminSignIn && other.user == user;
  }

  @override
  int get hashCode => user.hashCode;
}