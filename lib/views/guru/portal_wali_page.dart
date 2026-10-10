import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_helper.dart';

/// "Portal Wali + Guru" (v3.40) — pintasan bagi guru/pimpinan yang juga
/// orang tua: hubungkan akun wali (No HP) lalu masuki portal orang tua
/// tanpa login ulang.
class PortalWaliPage extends StatefulWidget {
  const PortalWaliPage({super.key});

  @override
  State<PortalWaliPage> createState() => _PortalWaliPageState();
}

class _PortalWaliPageState extends State<PortalWaliPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadIdentities();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadIdentities() async {
    final auth = context.read<AuthProvider>();
    await auth.getMyIdentities();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  static const Duration _snackDuration = Duration(seconds: 2);

  Future<void> _linkParent() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showErrorSnackBar(context, 'Masukkan No HP akun wali terlebih dahulu.', duration: _snackDuration);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.linkParentAccount(phone);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _phoneController.clear();
      showSuccessSnackBar(context, auth.successMessage ?? 'Akun wali berhasil dihubungkan.', duration: _snackDuration);
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? 'Gagal menghubungkan akun wali.', duration: _snackDuration);
    }
  }

  Future<void> _enterParentPortal() async {
    if (_busy) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.switchToParent();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      // Kembali ke root agar AuthGate beralih ke dashboard orang tua.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? 'Gagal memasuki portal wali.', duration: _snackDuration);
    }
  }

  Future<void> _unlinkParent() async {
    if (_busy) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.unlinkParentAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      showSuccessSnackBar(context, auth.successMessage ?? 'Kaitan akun wali diputuskan.', duration: _snackDuration);
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? 'Gagal memutuskan kaitan.', duration: _snackDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final parent = auth.linkedParent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Wali + Guru'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Penjelasan ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.family_restroom_rounded,
                          color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Jika Anda juga orang tua/wali santri, hubungkan '
                          'akun wali Anda (No HP) untuk masuk ke portal orang '
                          'tua tanpa login ulang.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (parent != null) ...[
                  // ── Akun wali terhubung ──
                  Text(
                    'Akun Wali Terhubung',
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
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withAlpha(30),
                        child: Icon(Icons.person_outline_rounded,
                            color: colorScheme.primary),
                      ),
                      title: Text(
                        (parent['name'] ?? '-').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'No HP: ${parent['phone'] ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.check_circle_outline,
                          color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _enterParentPortal,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(_busy ? 'Memproses...' : 'Masuk Portal Wali'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _busy ? null : _unlinkParent,
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text('Putuskan Kaitan Akun Wali'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ] else ...[
                  // ── Belum terhubung: form No HP ──
                  Text(
                    'Hubungkan Akun Wali',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 15,
                    decoration: InputDecoration(
                      labelText: 'No HP akun wali',
                      hintText: 'contoh: 0812xxxxxxx',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _linkParent(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _linkParent,
                    icon: const Icon(Icons.link_rounded),
                    label: Text(_busy ? 'Memproses...' : 'Hubungkan Akun Wali'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}