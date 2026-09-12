import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/gaji_guru_provider.dart';
import '../../utils/format.dart';

class GajiGuruPage extends StatefulWidget {
  const GajiGuruPage({super.key});

  @override
  State<GajiGuruPage> createState() => _GajiGuruPageState();
}

class _GajiGuruPageState extends State<GajiGuruPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => GajiGuruProvider()..init(),
      child: Consumer<GajiGuruProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Riwayat Bisyaroh',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.init,
                ),
              ],
            ),
            body: provider.isLoading
                ? _buildShimmerLoading(context)
                : provider.error != null
                    ? _buildErrorState(provider, colorScheme)
                    : RefreshIndicator(
                        onRefresh: provider.init,
                        child: _buildContent(provider, colorScheme, theme),
                      ),
          );
        },
      ),
    );
  }

  Widget _buildContent(GajiGuruProvider provider, ColorScheme colorScheme, ThemeData theme) {
    if (provider.slips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha:0.3)),
          const SizedBox(height: 16),
          Text(
            'Belum ada data Bisyaroh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Slip Bisyaroh akan muncul di sini\nsetelah admin memprosesnya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha:0.6), fontSize: 12),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // ── Ringkasan ──
        _buildSummaryCards(provider, colorScheme, theme),
        const SizedBox(height: 20),

        // ── Daftar Slip ──
        Row(
          children: [
            Icon(Icons.receipt_long_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Daftar Slip Bisyaroh',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${provider.slips.length} slip',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...provider.slips.map((slip) => _buildSlipCard(slip, colorScheme, theme)),
      ],
    );
  }

  Widget _buildSummaryCards(GajiGuruProvider provider, ColorScheme colorScheme, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            icon: Icons.check_circle_outline,
            label: 'Dibayar',
            value: '${provider.jumlahDibayar} slip',
            subValue: formatRp(provider.totalGajiDibayar),
            color: Colors.green,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            icon: Icons.pending_outlined,
            label: 'Draft',
            value: '${provider.jumlahDraft} slip',
            subValue: formatRp(provider.totalGajiDraft),
            color: Colors.orange,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlipCard(Map<String, dynamic> slip, ColorScheme colorScheme, ThemeData theme) {
    final status = (slip['status'] ?? 'DRAFT').toString().toUpperCase();
    final isPaid = status == 'DIBAYAR';
    final period = slip['period'] ?? '-';
    final total = (slip['total'] ?? 0).toDouble();
    final jamMengajar = (slip['jam_mengajar'] ?? 0).toDouble();
    final subtotal = (slip['subtotal_mengajar'] ?? 0).toDouble();
    final tunjangan = (slip['tunjangan'] ?? 0).toDouble();
    final paidAt = slip['paid_at'];
    final notes = slip['notes'];

    // Breakdown per jenjang
    final detail = slip['detail'];
    List<dynamic> breakdown = [];
    if (detail is Map && detail['breakdown'] is List) {
      breakdown = detail['breakdown'];
    }

    // Tunjangan detail
    final tunjanganDetail = slip['tunjangan_detail'];
    List<dynamic> allowances = [];
    if (tunjanganDetail is List) {
      allowances = tunjanganDetail;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.colorScheme.surfaceContainerLow,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isPaid ? Colors.green : Colors.orange).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
              color: isPaid ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          title: Text(
            _formatPeriod(period),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 13, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${jamMengajar.toStringAsFixed(1)} jam mengajar',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRp(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPaid ? Colors.green.shade700 : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPaid ? Colors.green : Colors.orange).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Divider(color: colorScheme.outlineVariant.withValues(alpha:0.3)),
            const SizedBox(height: 4),

            // ── Breakdown Mengajar per Jenjang ──
            if (breakdown.isNotEmpty) ...[
              _buildSectionTitle('Rincian Mengajar', colorScheme),
              const SizedBox(height: 6),
              ...breakdown.map((b) => _buildDetailRow(
                '${b['nama_jenjang'] ?? 'Tanpa Jadwal'}',
                '${(b['jam'] ?? 0).toStringAsFixed(1)} jam × ${formatRp(b['tarif'])}',
                formatRp(b['subtotal']),
                colorScheme,
              )),
              const SizedBox(height: 8),
            ],

            // ── Subtotal & Tunjangan ──
            _buildDetailRow('Subtotal Mengajar', '', formatRp(subtotal), colorScheme),
            if (allowances.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...allowances.map((a) => _buildDetailRow(
                'Tunj. ${a['nama'] ?? '-'}',
                '',
                formatRp(a['nominal']),
                colorScheme,
              )),
            ],
            if (tunjangan > 0 && allowances.isEmpty) ...[
              const SizedBox(height: 4),
              _buildDetailRow('Tunjangan', '', formatRp(tunjangan), colorScheme),
            ],

            // ── Total ──
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Bisyaroh', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  Text(
                    formatRp(total),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary),
                  ),
                ],
              ),
            ),

            // ── Info Dibayar ──
            if (isPaid && paidAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event_available, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Dibayar: ${dateOnly(paidAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            // ── Catatan ──
            if (notes != null && notes.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notes.toString(),
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildDetailRow(String label, String detail, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
                if (detail.isNotEmpty)
                  Text(detail, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        ],
      ),
    );
  }

  String _formatPeriod(String period) {
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final parts = period.split('-');
    if (parts.length == 2) {
      final year = parts[0];
      final monthIdx = int.tryParse(parts[1]) ?? 0;
      if (monthIdx > 0 && monthIdx < months.length) {
        return '${months[monthIdx]} $year';
      }
    }
    return period;
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, _) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(GajiGuruProvider provider, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.init,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
