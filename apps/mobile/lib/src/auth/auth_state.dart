import '../api/generated/models/tether_status_response.dart';
import '../api/generated/models/user_response.dart';

enum AuthRouteState { loggedOut, needsTetherOnboarding, untethered, tethered }

class AuthState {
  const AuthState._({
    required this.route,
    this.user,
    this.tetherStatus,
    this.tetherOnboardingSkipped = false,
  });

  const AuthState.loggedOut() : this._(route: AuthRouteState.loggedOut);

  AuthState.authenticated({
    required UserResponse user,
    required TetherStatusResponse tetherStatus,
    required bool tetherOnboardingSkipped,
  }) : this._(
         route: tetherStatus.hasActiveTether
             ? AuthRouteState.tethered
             : tetherOnboardingSkipped
             ? AuthRouteState.untethered
             : AuthRouteState.needsTetherOnboarding,
         user: user,
         tetherStatus: tetherStatus,
         tetherOnboardingSkipped: tetherOnboardingSkipped,
       );

  final AuthRouteState route;
  final UserResponse? user;
  final TetherStatusResponse? tetherStatus;
  final bool tetherOnboardingSkipped;

  bool get isLoggedOut => route == AuthRouteState.loggedOut;
}
