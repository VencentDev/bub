import '../api/generated/models/tether_status_response.dart';
import '../api/generated/models/user_response.dart';

enum AuthRouteState {
  loggedOut,
  needsProfileOnboarding,
  needsTetherOnboarding,
  untethered,
  tethered,
}

class AuthState {
  const AuthState._({
    required this.route,
    this.user,
    this.tetherStatus,
    this.profileOnboardingComplete = true,
    this.tetherOnboardingComplete = false,
  });

  const AuthState.loggedOut() : this._(route: AuthRouteState.loggedOut);

  AuthState.authenticated({
    required UserResponse user,
    required TetherStatusResponse tetherStatus,
    required bool tetherOnboardingComplete,
    bool? profileOnboardingComplete,
  }) : this._(
         route:
             (profileOnboardingComplete ??
                     user.profileOnboardingComplete ??
                     true) ==
                 false
             ? AuthRouteState.needsProfileOnboarding
             : tetherStatus.hasActiveTether == true
             ? AuthRouteState.tethered
             : tetherOnboardingComplete
             ? AuthRouteState.untethered
             : AuthRouteState.needsTetherOnboarding,
         user: user,
         tetherStatus: tetherStatus,
         profileOnboardingComplete:
             profileOnboardingComplete ??
             user.profileOnboardingComplete ??
             true,
         tetherOnboardingComplete: tetherOnboardingComplete,
       );

  final AuthRouteState route;
  final UserResponse? user;
  final TetherStatusResponse? tetherStatus;
  final bool profileOnboardingComplete;
  final bool tetherOnboardingComplete;

  bool get isLoggedOut => route == AuthRouteState.loggedOut;
}
