import 'package:chw_tb/components/elegeant_route.dart';
import 'package:flutter/material.dart';
import '../views/screens/splash_screen.dart';
import '../views/interface/authentication/sign_in_screen.dart';
import '../views/interface/authentication/sign_up_screen.dart';
import '../views/screens/home_screen.dart';

class AppRouter {
  // Global navigator key to allow navigation outside of a BuildContext with a Navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return ElegantRoute.build(const SplashScreen());
      case '/sign-in':
        return ElegantRoute.build(const SignInScreen());
      case '/sign-up':
        return ElegantRoute.build(const SignUpScreen());
      case '/home':
        return ElegantRoute.build(const HomeScreen());
      default:
        return ElegantRoute.build(
          const Scaffold(body: Center(child: Text("404 - Page not found"))),
        );
    }
  }
}
