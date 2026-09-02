import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/api/api_service.dart';

/// Bottom sheet untuk membayar iuran dari SALDO TABUNGAN santri.
/// [childNim] diisi saat dipanggil dari portal orang tua → endpoint parent.
/// Mengembalikan `true` jika pembayaran berhasil.
Future<bool?> showBayarDariTabunganSheet(BuildContext context, {String? childNim}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _BayarDariTabunganSheet(childNim: childNim),
  );
}

class _BayarDariTabunganSheet extends StatefulWidget {
  final String? childNim;
  const _BayarDariTabunganSheet({this.childNim});

  @override
  State<_BayarDariTabunganSheet> createState() =>
      _BayarDariTabunganSheetState();
}

class _BayarDariTabunganSheetState extends State<_BayarDariTabunganSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _amountController = TextEditingController();

  static const _bulan = [
    'Syawal',
    'Dz. Qo\'dah',
    'Dz. Hijjah',
    'Muharram',
    'Shafar',
    'Rb, Ula',
    'Rb. Tsani',
    'Jmd, Ula',
    'Jmd. Tsani',
    'Rajab',
    'Sya\'ban',
  ];

  String _paymentType = 'YAUMIYAH';
  String? _month;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showError('Nominal pembayaran harus lebih besar dari Rp 0.');
      return;
    }
    if (_paymentType == 'YAUMIYAH' && _month == null) {
      _showError('Pilih bulan iuran terlebih dahulu.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final endpoint = widget.childNim != null
          ? '/parents/me/children/${widget.childNim}/pay-from-savings'
          : '/students/me/payments/from-savings';
      await _apiService.dio.post(
        endpoint,
        data: {'payment_type': _paymentType, 'month': _month, 'amount': amount},
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      String message = 'Gagal membayar dari tabungan.';
      if (e is DioException) {
        message = e.response?.data?['message']?.toString() ?? message;
      }
      _showError(message);
    }
  }

  void _showError(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bayar Iuran dari Tabungan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.childNim != null
                  ? 'Nominal akan dipotong dari saldo tabungan anak.'
                  : 'Nominal akan dipotong otomatis dari saldo tabungan Anda.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _paymentType,
              decoration: const InputDecoration(
                labelText: 'Jenis Pembayaran',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'YAUMIYAH',
                  child: Text('Iuran Yaumiyah (Bulanan)'),
                ),
                DropdownMenuItem(
                  value: 'DAFTAR_ULANG',
                  child: Text('Pendaftaran Ulang'),
                ),
              ],
              onChanged: (v) => setState(() => _paymentType = v ?? 'YAUMIYAH'),
            ),
            const SizedBox(height: 12),

            if (_paymentType == 'YAUMIYAH') ...[
              DropdownButtonFormField<String>(
                initialValue: _month,
                decoration: const InputDecoration(
                  labelText: 'Bulan',
                  border: OutlineInputBorder(),
                ),
                items: _bulan
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _month = v),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Bayar dari Tabungan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Saldo akan dicek otomatis oleh sistem.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
