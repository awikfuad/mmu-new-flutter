import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Web implementation of the Google Sign-In button.
///
/// The web platform does not support `GoogleSignIn.authenticate()` — it only
/// allows rendering the official Google Identity Services (GIS) button. The
/// ID token of a completed sign-in is delivered through
/// `GoogleSignIn.authenticationEvents`, which this widget forwards to
/// [onIdToken].
class _GoogleSignInWebButton extends StatefulWidget {
  const _GoogleSignInWebButton({
    required this.clientId,
    required this.onIdToken,
  });

  final String clientId;
  final void Function(String idToken) onIdToken;

  @override
  State<_GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

class _GoogleSignInWebButtonState extends State<_GoogleSignInWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await GoogleSignIn.instance.initialize(clientId: widget.clientId);
      _authSub = GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is! GoogleSignInAuthenticationEventSignIn) return;
        final idToken = event.user.authentication.idToken;
        if (idToken != null) {
          widget.onIdToken(idToken);
        } else {
          debugPrint('[google_signin_web] ID token kosong setelah sign-in.');
        }
      });
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      debugPrint('[google_signin_web] Gagal init GoogleSignIn: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox.shrink();
    }
    if (!_ready) {
      return const SizedBox(
        height: 48,
        width: double.infinity,
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: gsi_web.renderButton(
        configuration: gsi_web.GSIButtonConfiguration(
          type: gsi_web.GSIButtonType.standard,
          size: gsi_web.GSIButtonSize.large,
          shape: gsi_web.GSIButtonShape.pill,
          theme: gsi_web.GSIButtonTheme.outline,
          text: gsi_web.GSIButtonText.continueWith,
        ),
      ),
    );
  }
}

Widget? buildGoogleSignInButton({
  required String clientId,
  required void Function(String idToken) onIdToken,
}) {
  return _GoogleSignInWebButton(
    clientId: clientId,
    onIdToken: onIdToken,
  );
}