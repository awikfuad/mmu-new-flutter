import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/api/api_service.dart';
import '../../providers/pembayaran_provider.dart';
import '../../utils/format.dart';
import '../../widgets/murid_picker_sheet.dart';

class PembayaranPage extends StatefulWidget {
  const PembayaranPage({super.key});

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  Future<void> _openInputSheet(PembayaranAdminProvider prov) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _InputPaymentSheet(),
    );
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pembayaran berhasil dicatat!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) {
        prov.loadTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ChangeNotifierProvider(
        create: (_) => PembayaranAdminProvider()..loadTransactions(),
        child: Consumer<PembayaranAdminProvider>(
          builder: (context, provider, _) {
            final colorScheme = Theme.of(context).colorScheme;
            return Scaffold(
              // backgroundColor: colorScheme.surface,
              appBar: AppBar(
                elevation: 0,
                title: const Text(
                  'Pembayaran Santri',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                bottom: TabBar(
                  indicatorColor: colorScheme.primary,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Riwayat'),
                    Tab(text: 'Rekap'),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Input Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openInputSheet(provider),
              ),
              body: provider.isLoading
                  ? _buildShimmerLoading(context)
                  : TabBarView(
                      children: [
                        _buildRiwayatView(provider),
                        _buildRekapView(provider),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRiwayatView(PembayaranAdminProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.loadTransactions,
      child: provider.transactions.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _EmptyState(),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: provider.transactions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildSummary(provider);
                return _buildTransactionCard(
                  provider.transactions[index - 1],
                );
              },
            ),
    );
  }

  Widget _buildRekapView(PembayaranAdminProvider provider) {
    if (provider.recaps.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadTransactions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _EmptyState(),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadTransactions,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: provider.recaps.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildRekapSummary(provider);
          return _buildPeriodCard(provider.recaps[index - 1]);
        },
      ),
    );
  }

  Widget _buildSummary(PembayaranAdminProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _summaryChip(
              formatRp(provider.totalYaumiyah),
              'Total Yaumiyah',
              Icons.calendar_today_rounded,
              colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryChip(
              formatRp(provider.totalDaftarUlang),
              'Total Daftar Ulang',
              Icons.assignment_turned_in_rounded,
              colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapSummary(PembayaranAdminProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryChip(
                  formatRp(provider.totalYaumiyah),
                  'Total Yaumiyah',
                  Icons.calendar_today_rounded,
                  colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryChip(
                  formatRp(provider.totalDaftarUlang),
                  'Total Daftar Ulang',
                  Icons.assignment_turned_in_rounded,
                  colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryChip(
                  '${provider.totalPeriode}',
                  'Jumlah Tanggal',
                  Icons.calendar_month_outlined,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryChip(
                  formatRp(provider.totalSemua),
                  'Total Penerimaan',
                  Icons.payments_outlined,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(dynamic r) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final yaumiyah = (r['yaumiyah'] as num?)?.toInt() ?? 0;
    final daftarUlang = (r['daftarUlang'] as num?)?.toInt() ?? 0;
    final total = (r['total'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPeriodDetail(r),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r['period']?.toString() ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${r['count'] ?? 0} transaksi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _periodStat(
                        'Yaumiyah',
                        formatRp(yaumiyah),
                        colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _periodStat(
                        'Daftar Ulang',
                        formatRp(daftarUlang),
                        colorScheme.secondary,
                      ),
                    ),
                    Expanded(
                      child: _periodStat(
                        'Total',
                        formatRp(total),
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodStat(String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Buka daftar detail transaksi untuk satu periode rekap.
  void _showPeriodDetail(dynamic r) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = (r['items'] as List?) ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pembayaran ${r['period']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: items.length,
                itemBuilder: (_, i) => _buildTransactionCard(items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color..withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic t) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final type = (t['payment_type'] ?? '-').toString();
    final isDaftarUlang = type == 'DAFTAR_ULANG';
    final color = isDaftarUlang ? colorScheme.secondary : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant..withValues(alpha:0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t['student_name'] ?? '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isDaftarUlang ? 'DAFTAR ULANG' : 'YAUMIYAH',
                      style: TextStyle(
                        // color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'NIM: ${t['nim'] ?? '-'}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _infoRow(
                      Icons.payments_outlined,
                      formatRp(t['amount']),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (t['month'] != null)
                    Expanded(
                      child: _infoRow(
                        Icons.calendar_month_outlined,
                        t['month'].toString(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _infoRow(
                      Icons.payment_rounded,
                      (t['payment_method'] ?? '-').toString(),
                    ),
                  ),
                  Expanded(
                    child: _infoRow(
                      Icons.event_outlined,
                      dateOnly(t['payment_date']?.toString()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text, {
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: color ?? colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: colorScheme.onSurfaceVariant..withValues(alpha:0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Belum ada transaksi pembayaran.',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tekan "Input Pembayaran" untuk mencatat pembayaran santri.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------- FORM INPUT PEMBAYARAN ----------
class _InputPaymentSheet extends StatefulWidget {
  const _InputPaymentSheet();

  @override
  State<_InputPaymentSheet> createState() => _InputPaymentSheetState();
}

class _InputPaymentSheetState extends State<_InputPaymentSheet> {
  final ApiService _apiService = ApiService();

  static const _bulan = [
    'Muharram',
    'Shafar',
    'Rb. Ula',
    'Rb. Tsani',
    'Jm. Ula',
    'Jm. Tsani',
    'Ramadan',
    'Syawal',
    'Dz. Qo\'dah',
    'Dz. Hijjah',
    'Rajab',
    'Sya\'ban',
  ];

  Map<String, dynamic>? _selected;
  bool _payYaumiyah = false;
  bool _payDaftarUlang = false;
  String? _month;
  String _paymentMethod = 'CASH';
  final _yaumiyahController = TextEditingController();
  final _daftarUlangController = TextEditingController();
  final _transferNoteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _yaumiyahController.dispose();
    _daftarUlangController.dispose();
    _transferNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickMurid() async {
    final murid = await showMuridPicker(context);
    if (murid != null) {
      setState(() => _selected = murid);
    }
  }

  Future<void> _submit() async {
    if (_selected == null) {
      _showError('Silakan pilih santri terlebih dahulu.');
      return;
    }
    if (!_payYaumiyah && !_payDaftarUlang) {
      _showError(
        'Pilih minimal satu jenis pembayaran (Yaumiyah / Daftar Ulang).',
      );
      return;
    }
    final yaumiyahAmount = int.tryParse(_yaumiyahController.text.trim()) ?? 0;
    final daftarUlangAmount =
        int.tryParse(_daftarUlangController.text.trim()) ?? 0;
    if (_payYaumiyah && (yaumiyahAmount <= 0 || _month == null)) {
      _showError('Lengkapi bulan & nominal pembayaran Yaumiyah.');
      return;
    }
    if (_payDaftarUlang && daftarUlangAmount <= 0) {
      _showError('Lengkapi nominal pembayaran Daftar Ulang.');
      return;
    }
    if (_paymentMethod == 'TRANSFER' &&
        _transferNoteController.text.trim().isEmpty) {
      _showError('Keterangan pelacakan transfer wajib diisi.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _apiService.dio.post(
        '/payments/transactions',
        data: {
          'student_id': _selected!['id'],
          'pay_yaumiyah': _payYaumiyah,
          'yaumiyah_month': _payYaumiyah ? _month : null,
          'yaumiyah_amount': _payYaumiyah ? yaumiyahAmount : null,
          'pay_daftar_ulang': _payDaftarUlang,
          'daftar_ulang_amount': _payDaftarUlang ? daftarUlangAmount : null,
          'payment_method': _paymentMethod,
          'transfer_note': _paymentMethod == 'TRANSFER'
              ? _transferNoteController.text.trim()
              : null,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      String message = 'Gagal menyimpan pembayaran.';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                  color: colorScheme.onSurfaceVariant..withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Input Pembayaran Santri',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickMurid,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selected == null
                      ? colorScheme.surfaceContainerHighest.withValues(alpha:0.5)
                      : theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selected == null
                        ? colorScheme.outlineVariant
                        : colorScheme.primary,
                    width: _selected == null ? 1 : 1.5,
                  ),
                ),
                child: _selected == null
                    ? Row(
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Pilih Santri...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.primary,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            radius: 18,
                            child: Icon(
                              Icons.person,
                              color: colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selected!['name'] ?? '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'NIM: ${_selected!['nim'] ?? '-'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Ubah',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _payYaumiyah
                      ? colorScheme.primary
                      : colorScheme.outlineVariant..withValues(alpha:0.5),
                  width: _payYaumiyah ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Iuran Yaumiyah',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Pembayaran iuran bulanan',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    activeThumbColor: colorScheme.primary,
                    value: _payYaumiyah,
                    onChanged: (v) => setState(() => _payYaumiyah = v),
                  ),
                  if (_payYaumiyah) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _month,
                        dropdownColor: colorScheme.surfaceContainer,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Pilih Bulan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: _bulan
                            .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _month = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _yaumiyahController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Nominal Yaumiyah (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _payDaftarUlang
                      ? colorScheme.secondary
                      : colorScheme.outlineVariant..withValues(alpha:0.5),
                  width: _payDaftarUlang ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Pendaftaran Ulang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Biaya daftar ulang tahun ajaran',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    activeThumbColor: colorScheme.secondary,
                    value: _payDaftarUlang,
                    onChanged: (v) => setState(() => _payDaftarUlang = v),
                  ),
                  if (_payDaftarUlang)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: TextField(
                        controller: _daftarUlangController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Nominal Daftar Ulang (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'CASH'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'CASH'
                            ? colorScheme.primaryContainer.withValues(alpha:0.4)
                            : colorScheme.surfaceContainerHighest..withValues(alpha:0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _paymentMethod == 'CASH'
                              ? colorScheme.primary
                              : colorScheme.outlineVariant..withValues(alpha:0.5),
                          width: _paymentMethod == 'CASH' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: _paymentMethod == 'CASH'
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tunai (CASH)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _paymentMethod == 'CASH'
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'TRANSFER'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'TRANSFER'
                            ? colorScheme.secondaryContainer.withValues(alpha:0.4)
                            : colorScheme.surfaceContainerHighest..withValues(alpha:0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _paymentMethod == 'TRANSFER'
                              ? colorScheme.secondary
                              : colorScheme.outlineVariant..withValues(alpha:0.5),
                          width: _paymentMethod == 'TRANSFER' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 16,
                            color: _paymentMethod == 'TRANSFER'
                                ? colorScheme.secondary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Transfer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _paymentMethod == 'TRANSFER'
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_paymentMethod == 'TRANSFER') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _transferNoteController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Keterangan Transfer',
                  hintText: 'Contoh: BSI a/n Ahmad (No. Reff 12345)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Simpan Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}