import 'package:flutter/widgets.dart';

/// Stub (non-web) implementation of [buildGoogleSignInButton].
///
/// On Android/iOS the app renders its own button and drives the flow through
/// `GoogleSignIn.authenticate()`, so no platform-rendered button is needed.
Widget? buildGoogleSignInButton({
  required String clientId,
  required void Function(String idToken) onIdToken,
}) {
  return null;
}