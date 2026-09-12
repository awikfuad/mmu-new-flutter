import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/google_signin_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum LoginMode { guru, santri, orangTua }

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _googleBusy = false;
  LoginMode _loginMode = LoginMode.guru;

  // Client ID Google (web) — di-inject saat build:
  //   flutter build --dart-define=GOOGLE_CLIENT_ID=<WEB_CLIENT_ID.apps.googleusercontent.com>
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '904890785521-gv6k0n0taspm56anr2bq0n13i6di3o74.apps.googleusercontent.com',
  );
  bool get _googleEnabled => _loginMode == LoginMode.guru && _googleClientId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Tampilkan notifikasi bila ada pesan sesi (mis. "Sesi berakhir, silakan login ulang").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.errorMessage == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      auth.clearError();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onModeChanged(LoginMode mode) {
    setState(() {
      _loginMode = mode;
      _usernameController.clear();
      _passwordController.clear();
      _formKey.currentState?.reset();
      // Santri: tanggal lahir lebih nyaman terlihat, default tidak obscure.
      // Lainnya tetap obscure.
      _obscurePassword = mode != LoginMode.santri;
    });
  }

  void _processLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final bool success = switch (_loginMode) {
      LoginMode.guru => await auth.login(
          _usernameController.text,
          _passwordController.text,
        ),
      LoginMode.santri => await auth.loginStudent(
          _usernameController.text,
          _passwordController.text,
        ),
      LoginMode.orangTua => await auth.loginParent(
          _usernameController.text,
          _passwordController.text,
        ),
    };

    if (!mounted) return;

    if (success) {
      // Jangan tampilkan Snackbar di LoginPage — akan langsung diganti dashboard via main.dart.
      // Notifikasi sukses bisa di dashboard; di sini cukup diam (navigasi reaktif).
      // Jika tetap ingin feedback, gunakan ScaffoldMessenger di root (post-frame).
      final msg = auth.successMessage ?? 'Login berhasil';
      // Tampilkan sebentar sebelum navigasi, atau abaikan — pilih tampil singkat.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final cs = Theme.of(context).colorScheme;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: cs.error, size: 28),
              const SizedBox(width: 10),
              const Text('Login Gagal'),
            ],
          ),
          content: Text(auth.errorMessage ?? 'Terjadi kesalahan saat login.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showLoginError(String? message) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 28),
            const SizedBox(width: 10),
            const Text('Login Gagal'),
          ],
        ),
        content: Text(message ?? 'Terjadi kesalahan saat login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    if (_googleBusy) return;
    FocusScope.of(context).unfocus();
    setState(() => _googleBusy = true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: _googleClientId);

      GoogleSignInAccount account;
      try {
        account = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled ||
            e.code == GoogleSignInExceptionCode.interrupted) {
          return; // pengguna membatalkan
        }
        _showLoginError('Gagal memilih akun Google: $e');
        return;
      }

      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        _showLoginError(
          'Tidak menerima ID token dari Google. Pastikan client ID web sudah didaftarkan '
          'di Google Cloud Console (OAuth web client).',
        );
        return;
      }
      await _handleGoogleIdToken(idToken);
    } catch (e) {
      if (!mounted) return;
      _showLoginError('Gagal login dengan Google: $e');
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  /// Menukar ID token Google dengan sesi aplikasi via backend `/auth/google`.
  ///
  /// Dipakai oleh kedua jalur: native (`authenticate()`) dan web
  /// (`renderButton` → `authenticationEvents`).
  Future<void> _handleGoogleIdToken(String idToken) async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.loginGoogle(idToken);
    if (!mounted) return;
    setState(() => _googleBusy = false);
    if (success) {
      final msg = auth.successMessage ?? 'Login berhasil';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // Tampilkan dialog khusus bila Google menolak (akun belum tertaut) —
      // mencantumkan EMAIL akun Google yang dikirim, agar jelas akun mana
      // yang dipakai vs yang tertaut di akun guru/admin.
      final needLinkEmail = auth.googleNeedLinkEmail;
      if (needLinkEmail != null && needLinkEmail.isNotEmpty) {
        _showGoogleNeedLinkDialog(needLinkEmail);
      } else {
        _showLoginError(auth.errorMessage);
      }
    }
  }

  /// Dialog khusus saat server menolak login Google karena akun yg dipakai
  /// belum ditautkan ke akun guru/admin mana pun.
  void _showGoogleNeedLinkDialog(String googleEmail) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.g_mobiledata_rounded, color: cs.error, size: 28),
            const SizedBox(width: 10),
            const Expanded(child: Text('Belum Terhubung')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                googleEmail,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Akun Google di atas belum terhubung ke akun MMU mana pun. '
              'Login pakai username/password guru/admin, lalu hubungkan email '
              'Google yang SAMA lewat menu Profil → Akun Google.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: cs.primary, size: 26),
            const SizedBox(width: 10),
            const Text('Lupa Password?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (_loginMode) {
                LoginMode.santri => 'Untuk santri, password adalah tanggal lahir. Contoh: "26 Agustus 2016" atau "26/08/2016". Jika tetap gagal, hubungi admin/pengurus pondok untuk reset password.',
                LoginMode.orangTua => 'Hubungi admin/pengurus pondok untuk reset password orang tua. Sertakan No. HP Anda yang terdaftar.',
                LoginMode.guru => 'Hubungi Super Admin untuk reset password guru/admin. Admin dapat mereset via menu Data Pengguna.',
              },
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin: gunakan menu Data Pengguna → Reset Password',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return switch (_loginMode) {
        LoginMode.guru => 'Username wajib diisi',
        LoginMode.santri => 'NIM wajib diisi',
        LoginMode.orangTua => 'No. HP wajib diisi',
      };
    }
    if (_loginMode == LoginMode.orangTua) {
      final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 10 || digits.length > 15) return 'No. HP tidak valid (10-15 digit)';
    }
    if (_loginMode == LoginMode.santri) {
      if (v.length < 3) return 'NIM minimal 3 karakter';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.trim().isEmpty) {
      return switch (_loginMode) {
        LoginMode.santri => 'Tanggal lahir wajib diisi',
        _ => 'Password wajib diisi',
      };
    }
    if (_loginMode != LoginMode.santri && v.length < 3) {
      return 'Password minimal 3 karakter';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Logo App
                Image.asset(
                  'assets/images/mmu.png',
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  switch (_loginMode) {
                    LoginMode.guru => 'E-Presensi Asatidz',
                    LoginMode.santri => 'E-Presensi Santri',
                    LoginMode.orangTua => 'Portal Wali Murid',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  switch (_loginMode) {
                    LoginMode.guru => 'Kelola jadwal & presensi harian',
                    LoginMode.santri => 'Masuk menggunakan NIM Santri',
                    LoginMode.orangTua => 'Pantau absensi & kegiatan santri',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Container Card
                Card(
                  elevation: 0.5,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mode Selection (SegmentedButton)
                          SegmentedButton<LoginMode>(
                            segments: const [
                              ButtonSegment(
                                value: LoginMode.guru,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Guru'),
                                ),
                                icon: Icon(Icons.school_outlined, size: 18),
                              ),
                              ButtonSegment(
                                value: LoginMode.santri,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Santri'),
                                ),
                                icon: Icon(Icons.person_outline, size: 18),
                              ),
                              ButtonSegment(
                                value: LoginMode.orangTua,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Wali'),
                                ),
                                icon: Icon(Icons.family_restroom_outlined, size: 18),
                              ),
                            ],
                            selected: {_loginMode},
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onSelectionChanged: (s) => _onModeChanged(s.first),
                            showSelectedIcon: false,
                          ),
                          const SizedBox(height: 20),

                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            keyboardType: _loginMode == LoginMode.orangTua
                                ? TextInputType.phone
                                : TextInputType.text,
                            textInputAction: TextInputAction.next,
                            autofillHints: switch (_loginMode) {
                              LoginMode.guru => const [AutofillHints.username],
                              LoginMode.santri => const [AutofillHints.username],
                              LoginMode.orangTua => const [AutofillHints.telephoneNumber],
                            },
                            decoration: InputDecoration(
                              labelText: switch (_loginMode) {
                                LoginMode.guru => 'Username',
                                LoginMode.santri => 'NIM Santri',
                                LoginMode.orangTua => 'No. HP / Whatsapp',
                              },
                              prefixIcon: Icon(Icons.person_outline_rounded, color: cs.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cs.outlineVariant),
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerLow,
                            ),
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _processLogin(),
                            decoration: InputDecoration(
                              labelText: switch (_loginMode) {
                                LoginMode.guru => 'Password',
                                LoginMode.santri => 'Tanggal Lahir',
                                LoginMode.orangTua => 'Password',
                              },
                              hintText: _loginMode == LoginMode.santri ? '26 Agustus 2016 atau 26/08/2016' : null,
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: cs.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cs.outlineVariant),
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerLow,
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Submit Button
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: auth.isLoading ? null : _processLogin,
                            child: auth.isLoading
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: cs.primary,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'MASUK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                          if (_googleEnabled) ...[
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'ATAU',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (kIsWeb)
                              buildGoogleSignInButton(
                                clientId: _googleClientId,
                                onIdToken: _handleGoogleIdToken,
                              ) ??
                                  const SizedBox(height: 48)
                            else
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(color: cs.outlineVariant),
                                  foregroundColor: cs.onSurface,
                                ),
                                onPressed: _googleBusy || auth.isLoading
                                    ? null
                                    : _loginWithGoogle,
                                child: _googleBusy
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: cs.primary,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _googleBadge(),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Lanjutkan dengan Google',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                          ],
                          // const SizedBox(height: 4),
                          // Text(
                          //   'Login Google memakai email yg SAMA dgn yg sudah '
                          //   'dihubungkan ke akun guru/admin (menu Profil → Akun Google).',
                          //   textAlign: TextAlign.center,
                          //   style: TextStyle(
                          //     fontSize: 11,
                          //     color: cs.onSurfaceVariant,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleBadge() {
    return ClipOval(
      child: Container(
        width: 22,
        height: 22,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          'G',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.1,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFFEA4335),
                  Color(0xFFFBBC05),
                  Color(0xFF34A853),
                ],
              ).createShader(const Rect.fromLTWH(0, 0, 22, 22)),
          ),
        ),
      ),
    );
  }
}
