import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
  LoginMode _loginMode = LoginMode.guru;

  @override
  void initState() {
    super.initState();
    // Santri default tampilkan tanggal lahir (tidak obscure).
    // Guru/orang tua tetap obscure.
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

  void _fillCredentials(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      // Santri demo: tampilkan tanggal lahir jelas
      if (_loginMode == LoginMode.santri) _obscurePassword = false;
    });
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
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
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
                                      color: cs.onPrimary,
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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Demo Accounts Card
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(Icons.lightbulb_outline_rounded, size: 20, color: cs.primary),
                      title: Text(
                        'Gunakan Akun Demo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Ketuk untuk mengisi kredensial otomatis',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        if (_loginMode == LoginMode.santri) ...[
                          _buildDemoAccount(
                            username: '1376',
                            password: '26 Agustus 2016',
                            label: 'MADRASAH',
                            accentColor: cs.primary,
                          ),
                          _buildDemoAccount(
                            username: '557660',
                            password: '07/09/2018',
                            label: 'TPQ',
                            accentColor: cs.secondary,
                          ),
                        ] else if (_loginMode == LoginMode.guru) ...[
                          _buildDemoAccount(
                            username: 'admin',
                            password: 'awik1745',
                            label: 'ADMIN',
                            accentColor: cs.error,
                          ),
                          _buildDemoAccount(
                            username: 'ustadz_ahmad',
                            password: 'awik1645',
                            label: 'Semua Lembaga',
                          ),
                          _buildDemoAccount(
                            username: 'ustadz_demo_all',
                            password: 'asatidz123',
                            label: 'Semua Lembaga',
                          ),
                          _buildDemoAccount(
                            username: 'ustadz_demo',
                            password: 'asatidz123',
                            label: 'MADRASAH',
                          ),
                          _buildDemoAccount(
                            username: 'ustadzah_demo_tpq',
                            password: 'asatidz123',
                            label: 'TPQ',
                          ),
                        ] else ...[
                          _buildDemoAccount(
                            username: '081234567890',
                            password: 'orangtua123',
                            label: 'ORANG TUA',
                            accentColor: cs.tertiary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccount({
    required String username,
    required String password,
    required String label,
    Color? accentColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final Color chipColor = accentColor ?? cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _fillCredentials(username, password),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    children: [
                      TextSpan(
                        text: username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' • ',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: password,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
