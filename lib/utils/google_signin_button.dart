import 'package:flutter/widgets.dart';

import 'google_signin_button_stub.dart'
    if (dart.library.js_interop) 'google_signin_button_web.dart' as impl;

/// Builds the official Google Sign-In (GIS) button for the web.
///
/// Returns `null` on platforms where no platform-rendered button exists
/// (Android/iOS/etc.), so callers can fall back to their own UI.
///
/// When the user completes the flow, [onIdToken] fires with the Google ID
/// token.
Widget? buildGoogleSignInButton({
  required String clientId,
  required void Function(String idToken) onIdToken,
}) {
  return impl.buildGoogleSignInButton(
    clientId: clientId,
    onIdToken: onIdToken,
  );
}