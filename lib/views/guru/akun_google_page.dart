import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/google_signin_button.dart';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/cupertino.dart';

/// Halaman "Akun Google" — self-service agar guru/admin menautkan atau
/// memutuskan tautan akun Google-nya sendiri (mirip menu Profil di web).
class AkunGooglePage extends StatefulWidget {
  const AkunGooglePage({super.key});

  @override
  State<AkunGooglePage> createState() => _AkunGooglePageState();
}

class _AkunGooglePageState extends State<AkunGooglePage> {
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '904890785521-gv6k0n0taspm56anr2bq0n13i6di3o74.apps.googleusercontent.com',
  );

  bool _loading = true;
  bool _googleBusy = false;
  bool _configured = false;
  bool _linked = false;
  String? _googleEmail;
  String? _googlePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final auth = context.read<AuthProvider>();
    final status = await auth.getGoogleAuthStatus();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _configured = status?['configured'] == true;
      _linked = status?['linked'] == true;
      _googleEmail = status?['google_email']?.toString();
      _googlePhotoUrl = status?['google_photo_url']?.toString();
    });
  }

  static const Duration _snackDuration = Duration(seconds: 2);

  Future<void> _linkWithGoogle() async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    try {
      // API google_sign_in v7.x+ menggunakan .instance & initialize
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: _googleClientId,
      );

      GoogleSignInAccount account;
      try {
        account = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled ||
            e.code == GoogleSignInExceptionCode.interrupted) {
          return; // Pengguna membatalkan
        }
        if (!mounted) return;
        showErrorSnackBar(context, 'Gagal memilih akun Google: $e', duration: _snackDuration);
        return;
      }

      final String? idToken = account.authentication.idToken;

      if (idToken == null) {
        if (!mounted) return;
        showErrorSnackBar(
          context,
          'Tidak menerima ID token dari Google. Pastikan Client ID sesuai.',
          duration: _snackDuration,
        );
        return;
      }

      await _submitLink(
        idToken,
        photoUrl: account.photoUrl,
        displayName: account.displayName,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal menautkan akun Google: $e', duration: _snackDuration);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

 Future<void> _submitLink(
  String idToken, {
  String? photoUrl,
  String? displayName,
}) async {
  final auth = context.read<AuthProvider>();

  // Kirim idToken ke backend API melalui Provider
  final success = await auth.linkGoogle(idToken);

  if (!mounted) return;
  if (success) {
    showSuccessSnackBar(context, auth.successMessage ?? 'Akun Google berhasil ditautkan.', duration: _snackDuration);
    await _loadStatus(); // Refresh status tampilan menjadi 'Terhubung'
  } else {
    showErrorSnackBar(context, auth.errorMessage ?? 'Gagal menautkan akun Google.', duration: _snackDuration);
  }
}

  Future<void> _confirmUnlink() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Putuskan Tautan Google?'),
        content: Text(
          _googleEmail != null
              ? 'Akun ${_googleEmail!} tidak lagi dapat digunakan untuk login '
                  'admin/guru di aplikasi ini.'
              : 'Tautan Google akan diputuskan dari akun Anda.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.unlinkGoogle();
    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(context, auth.successMessage ?? 'Tautan Google diputuskan.', duration: _snackDuration);
      await _loadStatus();
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? 'Gagal memutuskan tautan Google.', duration: _snackDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun Google'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // ── Status kartu ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _linked
                            ? Colors.green.shade600.withAlpha(102)
                            : colorScheme.outlineVariant.withAlpha(76),
                      ),
                    ),
                    child: Column(
                      children: [
                        // ── Avatar Profil / Icon Status ──
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: _linked
                              ? Colors.green.withAlpha(38)
                              : colorScheme.surfaceContainerHighest,
                          backgroundImage: (_linked &&
                                  _googlePhotoUrl != null &&
                                  _googlePhotoUrl!.isNotEmpty)
                              ? NetworkImage(_googlePhotoUrl!)
                              : null,
                          child: (_linked &&
                                  _googlePhotoUrl != null &&
                                  _googlePhotoUrl!.isNotEmpty)
                              ? null
                              : Icon(
                                  _linked
                                      ? CupertinoIcons.checkmark_circle
                                      : CupertinoIcons.link,
                                  size: 32,
                                  color: _linked
                                      ? Colors.green.shade700
                                      : colorScheme.onSurfaceVariant,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _linked ? 'Terhubung' : 'Belum terhubung',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _linked
                                ? Colors.green.shade800
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (_linked && _googleEmail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _googleEmail!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (_linked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Akun ini dapat login dengan tombol "Lanjutkan dengan Google".',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Belum dikonfigurasi server ──
                  if (!_configured) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withAlpha(102),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.info_circle, color: colorScheme.onErrorContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Login Google belum diaktifkan di server. '
                              'Hubungi admin untuk mengaktifkannya terlebih dahulu.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Tombol tindakan ──
                  if (_configured) ...[
                    if (!_linked) ...[
                      if (_googleClientId.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Fitur ini belum tersedia: build aplikasi ini tidak '
                            'menyertakan GOOGLE_CLIENT_ID.\n\n'
                            'Pasang saat build: --dart-define=GOOGLE_CLIENT_ID=<web_client_id>',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ] else if (kIsWeb) ...[
                        buildGoogleSignInButton(
                          clientId: _googleClientId,
                          onIdToken: (idToken) => _submitLink(idToken),
                        ) ??
                            const SizedBox.shrink(),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _googleBusy ? null : _linkWithGoogle,
                            icon: _googleBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 22),
                            label: const Text('Hubungkan Akun Google'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _googleBusy ? null : _confirmUnlink,
                          icon: const Icon(CupertinoIcons.link, size: 20),
                          label: const Text('Putuskan Tautan Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error.withAlpha(153)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}