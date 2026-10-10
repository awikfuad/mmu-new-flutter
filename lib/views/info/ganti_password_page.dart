import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';

/// Halaman ganti password mandiri — berlaku utk semua role (guru/admin,
/// santri, orang tua). Password baru diverifikasi terhadap kriteria kekuatan
/// lalu dikirim ke POST /auth/change-password. Re-login otomatis dilakukan di
/// dalam [AuthProvider.changePassword] agar refresh token (yg di-revoke
/// backend) diperbarui.
class GantiPasswordPage extends StatefulWidget {
  const GantiPasswordPage({super.key});

  @override
  State<GantiPasswordPage> createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends State<GantiPasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasLength => _newController.text.length >= 8;
  bool get _hasUpper => _newController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _newController.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _newController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newController.text.contains(RegExp(r'[^A-Za-z0-9]'));
  bool get _passesCriteria =>
      _hasLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

  Future<void> _submit() async {
    final current = _currentController.text;
    final password = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      setState(() => _errorText = 'Password lama wajib diisi.');
      return;
    }
    if (!_passesCriteria) {
      setState(() => _errorText = 'Password baru belum memenuhi semua kriteria di bawah.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = 'Konfirmasi password tidak sama.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final bio = context.read<BiometricProvider>();

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final ok = await auth.changePassword(
      currentPassword: current,
      newPassword: password,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      // Password akun berubah → kredensial biometrik (login sidik jari) lama
      // tidak lagi valid. Dibersihkan agar login sidik jari tidak gagal.
      if (bio.isBiometricEnabled) {
        await bio.clearCredentials();
      }
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() => _errorText =
          auth.errorMessage ?? 'Gagal mengubah password. Coba lagi.');
    }
  }

  Widget _criteriaRow(String label, bool ok) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? cs.primary : cs.outlineVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: ok ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label, bool obscure, VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Password'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_reset, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Password baru harus memenuhi semua kriteria berikut agar '
                    'akun Anda aman.',
                    style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentController,
            obscureText: _obscureCurrent,
            decoration: _decoration(
              'Password Lama',
              _obscureCurrent,
              () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            obscureText: _obscureNew,
            onChanged: (_) => setState(() {}),
            decoration: _decoration(
              'Password Baru',
              _obscureNew,
              () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: _decoration(
              'Ulangi Password Baru',
              _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kriteria password:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _criteriaRow('Minimal 8 karakter', _hasLength),
          const SizedBox(height: 4),
          _criteriaRow('Mengandung huruf besar (A-Z)', _hasUpper),
          const SizedBox(height: 4),
          _criteriaRow('Mengandung huruf kecil (a-z)', _hasLower),
          const SizedBox(height: 4),
          _criteriaRow('Mengandung angka (0-9)', _hasDigit),
          const SizedBox(height: 4),
          _criteriaRow('Mengandung karakter spesial (!@#... )', _hasSpecial),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorText!,
                style: TextStyle(fontSize: 13, color: cs.onErrorContainer),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_submitting ? 'Menyimpan...' : 'Simpan'),
          ),
        ],
      ),
    );
  }
}