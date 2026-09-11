// File: google_signin_button_web.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

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
  String? _lastIdToken;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ── DITARUH DI SINI (METHOD _init) ──
  Future<void> _init() async {
    try {
      await GoogleSignIn.instance.initialize(clientId: widget.clientId);

      _authSub = GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (!mounted) return;
        if (event is! GoogleSignInAuthenticationEventSignIn) return;
        final idToken = event.user.authentication.idToken;
        if (idToken == null || idToken == _lastIdToken) return;

        _lastIdToken = idToken;
        widget.onIdToken(idToken); // Mengirim ID Token langsung ke backend
      });

      if (!mounted) return;
      setState(() => _ready = true);

      // Memicu pemeriksaan sesi/prompt otomatis tanpa popup pilihan
      GoogleSignIn.instance.supportsAuthenticate();
    } catch (e) {
      debugPrint('[google_signin_web] Error init GoogleSignIn: $e');
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
    if (_failed) return const SizedBox.shrink();

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