import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../theme/theme_selector_dialog.dart';
import '../guru/akun_google_page.dart';
import 'ganti_password_page.dart';
import 'package:flutter/cupertino.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {
      // Abaikan — versi fallback ditampilkan bila info gagal dimuat.
    }
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      showErrorSnackBar(context, 'Gagal membuka link: $urlString');
    }
  }

  Future<void> _openGantiPassword() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GantiPasswordPage()),
    );
    if (changed == true && mounted) {
      showSuccessSnackBar(context, 'Password berhasil diubah.');
    }
  }

  /// Aktifkan login sidik jari. Password diambil otomatis dari sesi login yang
  /// sedang aktif (tanpa meminta input ulang) dan memakai kunci perangkat yang
  /// sudah terdaftar di sistem — tidak ada proses pendaftaran sidik jari baru.
  Future<void> _enableFingerprint(BiometricProvider bio) async {
    final auth = context.read<AuthProvider>();
    if (!bio.canCheckBiometrics) {
      showErrorSnackBar(context, 'Perangkat Anda tidak mendukung sidik jari / kunci layar.');
      return;
    }

    final identifier = _accountIdentifier(auth);
    if (identifier == null || identifier.isEmpty) {
      showErrorSnackBar(context, 'Tidak dapat mengaktifkan sidik jari: identitas akun tidak diketahui.');
      return;
    }

    // Password dari sesi login aktif → aktifkan tanpa meminta input lagi.
    final sessionPassword = auth.lastLoginPassword;
    if (sessionPassword != null && sessionPassword.isNotEmpty) {
      final confirmed = await _confirmEnableFingerprint();
      if (confirmed != true) return;
      await bio.saveCredentials(
        username: identifier,
        password: sessionPassword,
        loginMode: _loginMode(auth),
      );
      if (mounted) showSuccessSnackBar(context, 'Login sidik jari berhasil diaktifkan.');
      return;
    }

    // Fallback: sesi dipulihkan tanpa password (restore) / login Google.
    await _enableFingerprintWithPassword(bio, auth, identifier);
  }

  /// Konfirmasi ringkas sebelum mengaktifkan login sidik jari.
  Future<bool?> _confirmEnableFingerprint() {
    final cs = Theme.of(context).colorScheme;
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.lock, color: cs.primary, size: 28),
            const SizedBox(width: 10),
            const Text('Aktifkan Login Sidik Jari'),
          ],
        ),
        content: const Text(
          'Login berikutnya bisa memakai sidik jari / PIN kunci layar perangkat '
          'Anda (yang sudah terdaftar di sistem). Tidak perlu mendaftar sidik '
          'jari baru.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  /// Fallback saat password sesi tidak tersedia (sesi dipulihkan / login Google):
  /// minta password akun sekali untuk disimpan sebagai kredensial auto-login.
  Future<void> _enableFingerprintWithPassword(
    BiometricProvider bio,
    AuthProvider auth,
    String identifier,
  ) async {
    // Login via Google tidak punya password lokal → tidak bisa pakai kredensial.
    final role = auth.userRole;
    final canHavePassword = role == 'admin' || role == 'teacher' || role == 'user' || role == 'parent';
    if (!canHavePassword) {
      showErrorSnackBar(context, 'Login sidik jari tidak tersedia untuk akun ini.');
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final submitted = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool loading = false;
          String? errorText;
          Future<void> request() async {
            setDialogState(() {
              loading = true;
              errorText = null;
            });
            FocusScope.of(ctx).unfocus();

            if (controller.text.isEmpty) {
              setDialogState(() {
                loading = false;
                errorText = 'Password akun wajib diisi.';
              });
              return;
            }

            // Password akun disimpan utk auto-login via sidik jari nanti.
            await bio.saveCredentials(
              username: identifier,
              password: controller.text,
              loginMode: _loginMode(auth),
            );
            setDialogState(() => loading = false);
            if (ctx.mounted) Navigator.of(ctx).pop(true);
          }

          return CupertinoAlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.lock, color: cs.primary, size: 28),
                const SizedBox(width: 10),
                const Text('Aktifkan Login Sidik Jari'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withAlpha(102),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(CupertinoIcons.info_circle, size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Masukkan password akun sekali untuk disimpan sebagai '
                          'kredensial login otomatis memakai sidik jari perangkat.',
                          style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('Identitas akun: $identifier',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Akun',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorText!,
                    style: TextStyle(fontSize: 13, color: cs.error),
                  ),
                ],
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: loading ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: loading ? null : request,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(CupertinoIcons.lock, size: 18),
                    const SizedBox(width: 6),
                    Text(loading ? 'Menyimpan...' : 'Simpan'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    if (submitted == true && mounted) {
      showSuccessSnackBar(context, 'Login sidik jari berhasil diaktifkan.');
    }
    controller.dispose();
  }

  Future<void> _disableFingerprint(BiometricProvider bio) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.lock, color: cs.primary, size: 28),
            const SizedBox(width: 10),
            const Text('Nonaktifkan Login Sidik Jari?'),
          ],
        ),
        content: const Text(
          'Kredensial login otomatis akan dihapus dari perangkat ini. '
          'Anda harus login manual memakai password di lain waktu.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await bio.clearCredentials();
      if (!mounted) return;
      showSuccessSnackBar(context, 'Login sidik jari dinonaktifkan.');
    }
  }

  /// Identitas login akun saat ini utk kredensial biometrik.
  String? _accountIdentifier(AuthProvider auth) {
    final role = auth.userRole;
    if (role == 'user') return auth.user?['nim']?.toString();
    if (role == 'parent') return auth.user?['phone']?.toString();
    return auth.user?['username']?.toString();
  }

  /// Mode login (nilai yg disimpan BiometricProvider & dipakai login_page).
  String _loginMode(AuthProvider auth) {
    final role = auth.userRole;
    if (role == 'user') return 'santri';
    if (role == 'parent') return 'orangTua';
    return 'guru';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.read<ThemeProvider>();

    return Scaffold(
      body: Consumer<BiometricProvider>(
        builder: (context, bio, _) => CustomScrollView(
          slivers: [
            // ── Header Custom via SliverAppBar ──
            SliverAppBar(
              pinned: true,
              expandedHeight: 220.0,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Tentang Aplikasi',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.tertiary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/mmu.png',
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  CupertinoIcons.book,
                                  size: 60,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'E-Presensi MMU A44',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _packageInfo == null
                                ? 'Membaca versi...'
                                : 'Versi ${_packageInfo!.version} (Build ${_packageInfo!.buildNumber})',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimary.withAlpha(200),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Konten Utama ──
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Deskripsi Singkat ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withAlpha(76),
                      ),
                    ),
                    child: Text(
                      'Aplikasi E-Presensi Guru dan Layanan Akademik Madrasah Miftahul Ulum (MMU) A44 Warungdowo. '
                      'Dirancang untuk mempermudah pencatatan kehadiran KBM, mode piket, rekapitulasi bisyaroh, serta koordinasi internal asatidz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Pengaturan Akun ──
                  Text(
                    'Pengaturan & Integrasi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ganti Password (guru / santri / orang tua)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(76),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withAlpha(30),
                        child: Icon(CupertinoIcons.lock_rotation, color: colorScheme.primary),
                      ),
                      title: const Text(
                        'Ganti Password',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Perbarui password akun dengan kriteria yang kuat',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                      onTap: _openGantiPassword,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Akun Google
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(76),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withAlpha(30),
                        child: Icon(CupertinoIcons.antenna_radiowaves_left_right, color: colorScheme.primary),
                      ),
                      title: const Text(
                        'Akun Google',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Tautkan akun Google untuk kemudahan login',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AkunGooglePage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login Sidik Jari / Biometrik (login lokal)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(76),
                      ),
                    ),
                    child: SwitchListTile.adaptive(
                      secondary: CircleAvatar(
                        backgroundColor: colorScheme.primary.withAlpha(30),
                        child: Icon(CupertinoIcons.lock, color: colorScheme.primary),
                      ),
                      title: const Text(
                        'Login Sidik Jari',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        bio.isBiometricEnabled
                            ? 'Aktif — login otomatis memakai sidik jari / kunci layar'
                            : bio.canCheckBiometrics
                                ? 'Login lokal lebih cepat memakai sidik jari / PIN perangkat'
                                : 'Perangkat belum mendukung sidik jari / kunci layar',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: bio.isBiometricEnabled,
                      onChanged: bio.canCheckBiometrics
                          ? (value) {
                              if (value) {
                                _enableFingerprint(bio);
                              } else {
                                _disableFingerprint(bio);
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tema & Warna Aplikasi
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(76),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withAlpha(30),
                        child: Icon(CupertinoIcons.paintbrush, color: colorScheme.primary),
                      ),
                      title: const Text(
                        'Tema & Warna Aplikasi',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Pilih tema dan warna yang sesuai dengan preferensimu',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => ThemeSelectorDialog(themeProvider: themeProvider),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Saluran Resmi Media Sosial ──
                  Text(
                    'Saluran Resmi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(76),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x22128C7E),
                            child: Icon(
                              CupertinoIcons.chat_bubble,
                              color: Color(0xFF128C7E),
                            ),
                          ),
                          title: const Text('Saluran WhatsApp MMU A44'),
                          subtitle: const Text('Pusat informasi & pengumuman'),
                          trailing: const Icon(CupertinoIcons.arrow_up_right_square, size: 18),
                          onTap: () => _launchURL(
                            context,
                            'https://whatsapp.com/channel/0029VbCQjOtCXC3H0T0s7o2a',
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x22C13584),
                            child: Icon(
                              CupertinoIcons.camera,
                              color: Color(0xFFC13584),
                            ),
                          ),
                          title: const Text('Instagram Resmi'),
                          subtitle: const Text('@mmua44warungdowo'),
                          trailing: const Icon(CupertinoIcons.arrow_up_right_square, size: 18),
                          onTap: () => _launchURL(
                            context,
                            'https://www.instagram.com/mmua44warungdowo/',
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x22C4302B),
                            child: Icon(
                              CupertinoIcons.play_circle,
                              color: Color(0xFFC4302B),
                            ),
                          ),
                          title: const Text('MMU A44 TV'),
                          subtitle: const Text('Saluran YouTube Resmi'),
                          trailing: const Icon(CupertinoIcons.arrow_up_right_square, size: 18),
                          onTap: () => _launchURL(
                            context,
                            'https://youtube.com/@mmua44',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Footer Copyright ──
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} MMU A44 Warungdowo.\nAll rights reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}