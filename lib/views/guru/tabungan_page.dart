import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/api/api_service.dart';
import '../../providers/pembayaran_provider.dart';
import '../../utils/format.dart';
import '../../utils/foto_helper.dart';
import '../../widgets/murid_picker_sheet.dart';

class TabunganPage extends StatefulWidget {
  const TabunganPage({super.key});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  Future<void> _openTransactionSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TabunganAdminProvider>(),
        child: const _InputSavingsSheet(),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaksi tabungan berhasil dicatat!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.read<TabunganAdminProvider>().loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ChangeNotifierProvider(
        create: (_) => TabunganAdminProvider()..loadTransactions(),
        child: Consumer<TabunganAdminProvider>(
          builder: (context, provider, _) {
            final colorScheme = Theme.of(context).colorScheme;
            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                scrolledUnderElevation: 0.5,
                title: const Text(
                  'Tabungan Santri',
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
                elevation: 3,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Catat Transaksi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _openTransactionSheet,
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

  Widget _buildRiwayatView(TabunganAdminProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadTransactions(),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
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

  Widget _buildRekapView(TabunganAdminProvider provider) {
    if (provider.recaps.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadTransactions(),
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
      onRefresh: () => provider.loadTransactions(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: provider.recaps.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildRekapSummary(provider);
          return _buildPeriodCard(provider.recaps[index - 1]);
        },
      ),
    );
  }

  Widget _buildSummary(TabunganAdminProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _summaryChip(
              formatRp(provider.totalSetoran),
              'Total Setoran',
              Icons.arrow_downward_rounded,
              colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryChip(
              formatRp(provider.totalPenarikan),
              'Total Penarikan',
              Icons.arrow_upward_rounded,
              colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapSummary(TabunganAdminProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryChip(
                  formatRp(provider.totalSetoran),
                  'Total Setoran',
                  Icons.arrow_downward_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryChip(
                  formatRp(provider.totalPenarikan),
                  'Total Penarikan',
                  Icons.arrow_upward_rounded,
                  colorScheme.error,
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
                  'Jumlah Periode',
                  Icons.calendar_month_outlined,
                  colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryChip(
                  formatRp(provider.totalBersih),
                  'Saldo Bersih',
                  Icons.savings_outlined,
                  Colors.teal,
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
    final net = (r['net'] as num?)?.toInt() ?? 0;
    final setoran = (r['setoran'] as num?)?.toInt() ?? 0;
    final penarikan = (r['penarikan'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                      child: _periodStat('Setoran', formatRp(setoran), Colors.green),
                    ),
                    Expanded(
                      child: _periodStat('Penarikan', formatRp(penarikan), colorScheme.error),
                    ),
                    Expanded(
                      child: _periodStat(
                        'Bersih',
                        formatRp(net),
                        net < 0 ? colorScheme.error : Colors.teal,
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

  /// Buka daftar detail mutasi untuk satu periode rekap.
  void _showPeriodDetail(dynamic r) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = (r['items'] as List?) ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      'Mutasi ${r['period']}',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontSize: 11,
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
    final isPenarikan =
        (t['transaction_type'] ?? '').toString() == 'PENARIKAN';
    final color = isPenarikan ? colorScheme.error : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha:0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha:0.12),
                    child: Icon(
                      isPenarikan
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['student_name'] ?? '-',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'NIM: ${t['nim'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPenarikan ? 'PENARIKAN' : 'SETORAN',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                // mainAxisAlignment: MainAxisAlignment.,
                children: [
                  Expanded(
                    child: _infoRow(
                      Icons.payments_outlined,
                      formatRp(t['amount']),
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: _infoRow(
                      Icons.event_outlined,
                      dateOnly(t['saving_date']?.toString()),
                    ),
                  ),
                ],
              ),
              if (t['notes'] != null && t['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(
                  Icons.text_snippet_outlined,
                  t['notes'].toString(),
                ),
              ],
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
      mainAxisSize: MainAxisSize.min,
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
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Container(
            height: 95,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
          Icons.savings_outlined,
          size: 64,
          color: colorScheme.onSurfaceVariant.withValues(alpha:0.4),
        ),
        const SizedBox(height: 12),
        Text(
          'Belum ada transaksi tabungan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tekan tombol "+ Catat Transaksi" untuk menambahkan.',
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

// ---------- FORM INPUT TRANSAKSI TABUNGAN ----------
class _InputSavingsSheet extends StatefulWidget {
  const _InputSavingsSheet();

  @override
  State<_InputSavingsSheet> createState() => _InputSavingsSheetState();
}

class _InputSavingsSheetState extends State<_InputSavingsSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _selected;
  String _transactionType = 'SETORAN';
  bool _submitting = false;
  num? _balance;
  bool _balanceLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickMurid() async {
    final murid = await showMuridPicker(context);
    if (murid != null) {
      setState(() => _selected = murid);
      _loadBalance();
    }
  }

  /// Ambil saldo tabungan santri terpilih (endpoint /savings/dashboard/:id).
  Future<void> _loadBalance() async {
    final id = _selected?['id'];
    if (id == null) return;
    setState(() {
      _balance = null;
      _balanceLoading = true;
    });
    try {
      final res = await _apiService.dio.get('/savings/dashboard/$id');
      if (!mounted) return;
      setState(() => _balance = (res.data['total_balance'] as num?) ?? 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _balance = null);
    } finally {
      if (mounted) setState(() => _balanceLoading = false);
    }
  }

  /// Prediksi saldo setelah transaksi berdasarkan jenis & nominal yang diisi.
  num? get _predictedBalance {
    if (_balance == null) return null;
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    return _transactionType == 'PENARIKAN'
        ? _balance! - amount
        : _balance! + amount;
  }

  Future<void> _submit() async {
    if (_selected == null) {
      _showError('Silakan pilih santri terlebih dahulu.');
      return;
    }
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showError('Nominal transaksi harus lebih besar dari Rp 0.');
      return;
    }

    if (_transactionType == 'PENARIKAN' &&
        _balance != null &&
        amount > _balance!) {
      _showError(
          'Saldo tidak mencukupi! Saldo saat ini: ${formatRp(_balance!)}');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _apiService.dio.post(
        '/savings/transaction',
        data: {
          'student_id': _selected!['id'],
          'transaction_type': _transactionType,
          'amount': amount,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
  setState(() => _submitting = false);
  String message = 'Gagal menyimpan transaksi tabungan.';
  if (e is DioException) {
    // 💡 Tambahkan log ini untuk melihat response detail dari server di console:
    debugPrint('Status Code: ${e.response?.statusCode}');
    debugPrint('Response Data: ${e.response?.data}');
    
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final penarikanMelebihiSaldo =
        _transactionType == 'PENARIKAN' && _balance != null && amount > _balance!;
    final infoColor = _balanceLoading
        ? colorScheme.onSurfaceVariant
        : penarikanMelebihiSaldo
            ? colorScheme.error
            : colorScheme.primary;

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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(Icons.savings_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Catat Transaksi Tabungan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Pilih Santri
            InkWell(
              onTap: _pickMurid,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selected == null
                      ? colorScheme.primaryContainer.withValues(alpha:0.2)
                      : theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
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
                            backgroundImage: cachedFotoProvider(_selected!['foto']?.toString()),
                            onBackgroundImageError: (_, _) {},
                            child: resolveFotoUrl(_selected!['foto']?.toString()) == null
                                ? Icon(
                                    Icons.person,
                                    color: colorScheme.onPrimaryContainer,
                                    size: 20,
                                  )
                                : null,
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

            // 1b. Info Saldo Santri Terpilih
            if (_selected != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: penarikanMelebihiSaldo
                      ? colorScheme.error.withValues(alpha: 0.08)
                      : colorScheme.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: penarikanMelebihiSaldo
                        ? colorScheme.error
                        : colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: infoColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _balanceLoading
                          ? Text(
                              'Memuat saldo tabungan...',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : _balance == null
                              ? Text(
                                  'Saldo tidak dapat dimuat.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saldo Saat Ini',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatRp(_balance!),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                    if (!_balanceLoading)
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Custom Toggle Jenis Transaksi
            Text(
              'Jenis Transaksi',
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
                    onTap: () => setState(() => _transactionType = 'SETORAN'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _transactionType == 'SETORAN'
                            ? colorScheme.primary.withValues(alpha:0.1)
                            : colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _transactionType == 'SETORAN'
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(alpha:0.5),
                          width: _transactionType == 'SETORAN' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: _transactionType == 'SETORAN'
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Setoran (Simpan)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _transactionType == 'SETORAN'
                                  ? colorScheme.primary
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
                    onTap: () => setState(() => _transactionType = 'PENARIKAN'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _transactionType == 'PENARIKAN'
                            ? colorScheme.error.withValues(alpha:0.1)
                            : colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _transactionType == 'PENARIKAN'
                              ? colorScheme.error
                              : colorScheme.outlineVariant.withValues(alpha:0.5),
                          width: _transactionType == 'PENARIKAN' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: _transactionType == 'PENARIKAN'
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Penarikan (Tarik)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _transactionType == 'PENARIKAN'
                                  ? colorScheme.error
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
            const SizedBox(height: 16),

            // 3. Nominal Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Nominal Transaksi',
                hintText: '0',
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3b. Prediksi saldo setelah transaksi
            if (_balance != null) ...[
              Row(
                children: [
                  Icon(
                    _transactionType == 'PENARIKAN'
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    size: 16,
                    color: penarikanMelebihiSaldo
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      penarikanMelebihiSaldo
                          ? 'Saldo tidak mencukupi'
                          : 'Saldo setelah transaksi: ${formatRp(_predictedBalance!)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: penarikanMelebihiSaldo
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // 4. Catatan Input
            TextField(
              controller: _notesController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: Tabungan sisa uang saku',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                        'Simpan Transaksi',
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