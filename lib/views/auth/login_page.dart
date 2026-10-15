import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../utils/google_signin_button.dart';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/shimmer_loader.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum LoginMode { guru, santri, orangTua }

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _googleBusy = false;
  LoginMode _loginMode = LoginMode.guru;
  bool _registerMode = false;
  PackageInfo? _packageInfo;

  // Variabel Animasi
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {
      // Abaikan — versi fallback ditampilkan bila info gagal dimuat.[cite: 9]
    }
  }

  // Client ID Google (web) — di-inject saat build:[cite: 9]
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '904890785521-gv6k0n0taspm56anr2bq0n13i6di3o74.apps.googleusercontent.com',
  );

  bool get _googleEnabled =>
      _loginMode == LoginMode.guru && _googleClientId.isNotEmpty;

  bool get _googleRegisterEnabled =>
      (_loginMode == LoginMode.guru || _loginMode == LoginMode.orangTua) &&
      _googleClientId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();

    // Inisialisasi Controller Animasi
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.errorMessage != null) {
        showErrorSnackBar(context, auth.errorMessage!);
        auth.clearError();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onModeChanged(LoginMode mode) {
    setState(() {
      _loginMode = mode;
      _registerMode = false;
      _usernameController.clear();
      _passwordController.clear();
      _formKey.currentState?.reset();
      _obscurePassword = mode != LoginMode.santri;
    });
  }

  Future<void> _processLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final bio = context.read<BiometricProvider>();

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final bool success = switch (_loginMode) {
      LoginMode.guru => await auth.login(username, password),
      LoginMode.santri => await auth.loginStudent(username, password),
      LoginMode.orangTua => await auth.loginParent(username, password),
    };

    if (!mounted) return;

    if (success) {
      if (bio.canCheckBiometrics && !bio.isBiometricEnabled) {
        await _promptEnableBiometrics(username, password, _loginMode.name);
      }

      final msg = auth.successMessage ?? 'Login berhasil';
      if (mounted) {
        showSuccessSnackBar(context, msg, duration: const Duration(seconds: 1));
      }
    } else {
      _showLoginError(auth.errorMessage);
    }
  }

  Future<void> _loginWithBiometrics() async {
    final bio = context.read<BiometricProvider>();
    final auth = context.read<AuthProvider>();

    final isAuthenticated = await bio.authenticate();
    if (!isAuthenticated) return;

    final username = bio.savedUsername;
    final password = bio.savedPassword;
    final modeStr = bio.savedLoginMode;

    if (username == null || password == null || modeStr == null) return;

    final mode = LoginMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => LoginMode.guru,
    );

    setState(() => _loginMode = mode);

    final bool success = switch (mode) {
      LoginMode.guru => await auth.login(username, password),
      LoginMode.santri => await auth.loginStudent(username, password),
      LoginMode.orangTua => await auth.loginParent(username, password),
    };

    if (!mounted) return;

    if (success) {
      final msg = auth.successMessage ?? 'Login Biometrik Berhasil';
      showSuccessSnackBar(context, msg, duration: const Duration(seconds: 1));
    } else if (auth.lastLoginAuthFailed) {
      // Password tersimpan sudah tidak valid (mis. diganti dari perangkat lain).
      // Bersihkan agar tidak gagal berulang, lalu pandu aktifkan ulang.
      await bio.clearCredentials();
      if (!mounted) return;
      setState(() {
        _usernameController.text = username;
        _loginMode = mode;
      });
      _showLoginError(
        'Login sidik jari gagal — password akun mungkin sudah berubah.\n'
        'Silakan masukkan password terbaru, lalu aktifkan ulang sidik jari di '
        'Pengaturan → Tentang Aplikasi.',
      );
    } else {
      _showLoginError(
        auth.errorMessage ??
            'Gagal login otomatis. Silakan ketik ulang password Anda.',
      );
    }
  }

  Future<void> _promptEnableBiometrics(
    String username,
    String password,
    String modeName,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final enable = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.lock, color: cs.primary, size: 28),
            const SizedBox(width: 10),
            const Text('Aktifkan Biometrik?'),
          ],
        ),
        content: const Text(
          'Apakah Anda ingin mengaktifkan login Sidik Jari / Biometrik untuk masuk lebih cepat di lain waktu?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti Saja'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (enable == true && mounted) {
      await context.read<BiometricProvider>().saveCredentials(
            username: username,
            password: password,
            loginMode: modeName,
          );
    }
  }

  void _showLoginError(String? message) {
    final cs = Theme.of(context).colorScheme;
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_circle, color: cs.error, size: 28),
            const SizedBox(width: 10),
            const Text('Login Gagal'),
          ],
        ),
        content: Text(message ?? 'Terjadi kesalahan saat login.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
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

      GoogleSignInAccount? account;
      try {
        account = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled ||
            e.code == GoogleSignInExceptionCode.interrupted) {
          return;
        }
        _showLoginError('Gagal memilih akun Google: $e');
        return;
      }

      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        _showLoginError(
          'Tidak menerima ID token dari Google. Pastikan Web Client ID valid.',
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

  Future<void> _handleGoogleIdToken(String idToken) async {
    setState(() => _googleBusy = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.loginGoogle(idToken);

    if (!mounted) return;
    setState(() => _googleBusy = false);

    if (success) {
      final msg = auth.successMessage ?? 'Login berhasil';
      showSuccessSnackBar(context, msg, duration: const Duration(seconds: 1));
    } else {
      final needLinkEmail = auth.googleNeedLinkEmail;
      if (needLinkEmail != null && needLinkEmail.isNotEmpty) {
        _showGoogleNeedLinkDialog(needLinkEmail);
      } else {
        _showLoginError(auth.errorMessage);
      }
    }
  }

  void _showGoogleNeedLinkDialog(String googleEmail) {
    final cs = Theme.of(context).colorScheme;
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.antenna_radiowaves_left_right, color: cs.error, size: 28),
            const SizedBox(width: 10),
            const Text('Belum Terhubung'),
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
              'Login menggunakan username/password guru/admin, lalu hubungkan email '
              'Google yang SAMA lewat menu Profil → Akun Google.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleRegisterMode() {
    setState(() => _registerMode = !_registerMode);
  }

  Future<void> _registerWithGoogle() async {
    if (_googleBusy) return;
    FocusScope.of(context).unfocus();
    setState(() => _googleBusy = true);

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: _googleClientId);

      GoogleSignInAccount? account;
      try {
        account = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled ||
            e.code == GoogleSignInExceptionCode.interrupted) {
          return;
        }
        _showLoginError('Gagal memilih akun Google: $e');
        return;
      }

      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        _showLoginError('Tidak menerima ID token dari Google.');
        return;
      }

      await _handleRegisterGoogleIdToken(
        idToken,
        name: account.displayName,
        email: account.email,
      );
    } catch (e) {
      if (!mounted) return;
      _showLoginError('Gagal mendaftar dengan Google: $e');
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _handleRegisterGoogleIdToken(
    String idToken, {
    String? name,
    String? email,
  }) async {
    if (!mounted) return;
    final payload = _decodeGooglePayload(idToken);
    await _showGoogleRegisterDialog(
      idToken,
      name: name ?? (payload?['name'] as String?),
      email: email ?? (payload?['email'] as String?),
    );
  }

  Map<String, dynamic>? _decodeGooglePayload(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return null;
      final jsonStr = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showGoogleRegisterDialog(
    String idToken, {
    String? name,
    String? email,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final catatanController = TextEditingController();
    var submitting = false;
    String? error;
    var sent = false;

    await showCupertinoDialog(
      context: context,
      barrierDismissible: !submitting,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            setDialogState(() {
              submitting = true;
              error = null;
            });
            final auth = context.read<AuthProvider>();
            final ok = await auth.registerGoogle(
              idToken,
              catatan: catatanController.text,
            );
            if (!dialogContext.mounted) return;
            setDialogState(() {
              submitting = false;
              if (ok) {
                sent = true;
              } else if (auth.registrationPending) {
                error =
                    'Email ini sudah terdaftar dan masih menunggu konfirmasi admin.';
              } else {
                error = auth.errorMessage ?? 'Gagal mengirim pendaftaran.';
              }
            });
          }

          return CupertinoAlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.antenna_radiowaves_left_right, color: cs.primary, size: 28),
                const SizedBox(width: 10),
                const Text('Daftar Akun Baru'),
              ],
            ),
            content: sent
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.check_mark_circled,
                        color: cs.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pendaftaran Terkirim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registrasi akun dengan ${email ?? 'Google'} sedang '
                        'menunggu konfirmasi admin. Silakan login kembali setelah disetujui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (email != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$email${name != null && name.isNotEmpty ? ' · $name' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      TextField(
                        controller: catatanController,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: InputDecoration(
                          labelText: 'Catatan (opsional)',
                          hintText: 'Contoh: Guru mengaji, Wali murid, dsb.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.error,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
            actions: sent
                ? [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        if (mounted) setState(() => _registerMode = false);
                      },
                      child: const Text('OK'),
                    ),
                  ]
                : [
                    CupertinoDialogAction(
                      onPressed:
                          submitting ? null : () => Navigator.pop(dialogContext),
                      child: const Text('Batal'),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: submitting ? null : submit,
                      child: submitting
                          ? const ShimmerSpinner(size: 18, strokeWidth: 2)
                          : const Text('Kirim Pendaftaran'),
                    ),
                  ],
          );
        },
      ),
    );
    catatanController.dispose();
  }

  void _showForgotPasswordDialog() {
    final cs = Theme.of(context).colorScheme;
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.question_circle, color: cs.primary, size: 26),
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
                LoginMode.santri =>
                  'Untuk murid, password awal adalah tanggal lahir (contoh: "26/08/2016"). Hubungi pengurus jika bermasalah.',
                LoginMode.orangTua =>
                  'Hubungi admin untuk reset password orang tua. Sertakan No. HP terdaftar Anda.',
                LoginMode.guru =>
                  'Hubungi Super Admin untuk reset password akun guru/admin.',
              },
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
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
                  Icon(CupertinoIcons.info_circle, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin: gunakan menu Data Pengguna → Reset Password',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
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
      if (digits.length < 10 || digits.length > 15) {
        return 'No. HP tidak valid (10-15 digit)';
      }
    }
    if (_loginMode == LoginMode.santri && v.length < 3) {
      return 'NIM minimal 3 karakter';
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
    final bio = context.watch<BiometricProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Center(
       
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/mmu.png',
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        CupertinoIcons.book,
                        size: 80,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      switch (_loginMode) {
                        LoginMode.guru => 'E-Presensi Asatidz',
                        LoginMode.santri => 'E-Presensi Murid',
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
                        LoginMode.santri => 'Masuk menggunakan NIM Murid',
                        LoginMode.orangTua => 'Pantau absensi & kegiatan Murid',
                      },
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Card(
                      elevation: 0.5,
                      color: cs.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: cs.tertiary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<LoginMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: LoginMode.guru,
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Guru'),
                                    ),
                                    icon: Icon(CupertinoIcons.book, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: LoginMode.santri,
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Murid'),
                                    ),
                                    icon: Icon(CupertinoIcons.person, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: LoginMode.orangTua,
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Wali'),
                                    ),
                                    icon: Icon(
                                      CupertinoIcons.person_3,
                                      size: 18,
                                    ),
                                  ),
                                ],
                                selected: {_loginMode},
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onSelectionChanged: (s) => _onModeChanged(s.first),
                                showSelectedIcon: false,
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _usernameController,
                                keyboardType: _loginMode == LoginMode.orangTua
                                    ? TextInputType.phone
                                    : TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: switch (_loginMode) {
                                  LoginMode.guru => const [AutofillHints.username],
                                  LoginMode.santri => const [AutofillHints.username],
                                  LoginMode.orangTua => const [
                                    AutofillHints.telephoneNumber
                                  ],
                                },
                                decoration: InputDecoration(
                                  labelText: switch (_loginMode) {
                                    LoginMode.guru => 'Username',
                                    LoginMode.santri => 'NIM Murid',
                                    LoginMode.orangTua => 'No. HP / Whatsapp',
                                  },
                                  prefixIcon: Icon(
                                    CupertinoIcons.person,
                                    color: cs.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide:
                                        BorderSide(color: cs.outlineVariant),
                                  ),
                                  filled: true,
                                  fillColor: cs.surfaceContainerLow,
                                ),
                                validator: _validateUsername,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _processLogin(),
                                decoration: InputDecoration(
                                  labelText: switch (_loginMode) {
                                    LoginMode.guru => 'Password',
                                    LoginMode.santri => 'Password',
                                    LoginMode.orangTua => 'Password',
                                  },
                                  prefixIcon: Icon(
                                    CupertinoIcons.lock,
                                    color: cs.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? CupertinoIcons.eye_slash
                                          : CupertinoIcons.eye,
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
                                    borderSide:
                                        BorderSide(color: cs.outlineVariant),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: Text(
                                    'Lupa Password?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
  children: [
    Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: auth.isLoading
            ? Container(
                key: const ValueKey('loading_indicator'),
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: ShimmerSpinner(
                    size: 24,
                    strokeWidth: 2.5,
                    color: cs.primary,
                  ),
                ),
              )
            : FilledButton(
                key: const ValueKey('login_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _processLogin,
                child: const Text(
                  'MASUK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
      ),
    ),
    AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bio.isBiometricEnabled) ...[
            const SizedBox(width: 10),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                minimumSize: const Size(52, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: bio.isLoading
                  ? ShimmerSpinner(
                      size: 24,
                      strokeWidth: 2,
                      color: cs.primary,
                    )
                  : Icon(
                      CupertinoIcons.lock,
                      size: 28,
                      color: cs.primary,
                    ),
              onPressed: (bio.isLoading || auth.isLoading)
                  ? null
                  : _loginWithBiometrics,
              tooltip: 'Masuk dengan Biometrik',
            ),
          ],
        ],
      ),
    ),
  ],
),
                              if (_googleEnabled || _googleRegisterEnabled) ...[
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
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
                                if (_registerMode)
                                  Column(
                                    children: [
                                      Text(
                                        'Daftarkan akun baru dengan Google. Akun aktif '
                                        'setelah dikonfirmasi admin.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (kIsWeb)
                                        buildGoogleSignInButton(
                                              clientId: _googleClientId,
                                              registration: true,
                                              onIdToken:
                                                  _handleRegisterGoogleIdToken,
                                            ) ??
                                            const SizedBox(height: 48)
                                      else
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(48),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            side: BorderSide(
                                              color: cs.outlineVariant,
                                            ),
                                            foregroundColor: cs.onSurface,
                                          ),
                                          onPressed: _googleBusy || auth.isLoading
                                              ? null
                                              : _registerWithGoogle,
                                          child: _googleBusy
                                              ? ShimmerSpinner(
                                                  size: 20,
                                                  strokeWidth: 2.5,
                                                  color: cs.primary,
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _googleBadge(),
                                                    const SizedBox(width: 10),
                                                    const Text(
                                                      'Daftar dengan Google',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: _toggleRegisterMode,
                                        child:
                                            const Text('Sudah punya akun? Masuk'),
                                      ),
                                    ],
                                  )
                                else ...[
                                  if (_googleEnabled) ...[
                                    if (kIsWeb)
                                      buildGoogleSignInButton(
                                            clientId: _googleClientId,
                                            registration: false,
                                            onIdToken: _handleGoogleIdToken,
                                          ) ??
                                          const SizedBox(height: 48)
                                    else
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          side: BorderSide(
                                            color: cs.outlineVariant,
                                          ),
                                          foregroundColor: cs.onSurface,
                                        ),
                                        onPressed: _googleBusy || auth.isLoading
                                            ? null
                                            : _loginWithGoogle,
                                        child: _googleBusy
                                            ? ShimmerSpinner(
                                                size: 20,
                                                strokeWidth: 2.5,
                                                color: cs.primary,
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
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
                                  const SizedBox(height: 4),
                                  TextButton(
                                    onPressed: _toggleRegisterMode,
                                    child: const Text(
                                      'Belum punya akun? Daftar dengan Google',
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
        color: Colors.transparent,
        child: Text(
          _packageInfo == null
              ? 'E-Presensi MMU A44'
              : 'E-Presensi MMU A44 v${_packageInfo!.version}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
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