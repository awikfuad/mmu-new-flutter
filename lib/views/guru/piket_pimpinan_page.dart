import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/piket_pimpinan_provider.dart';
import 'package:flutter/cupertino.dart';

class PiketPimpinanPage extends StatelessWidget {
  const PiketPimpinanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PiketPimpinanProvider()..load(),
      child: const _PiketPimpinanBody(),
    );
  }
}

class _PiketPimpinanBody extends StatelessWidget {
  const _PiketPimpinanBody();

  static const List<String> _dayShort = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Ahad',
  ];

  Color _statusColor(String? status, ColorScheme cs) {
    switch (status?.toUpperCase()) {
      case 'HADIR':
        return Colors.green.shade600;
      case 'SAKIT':
        return Colors.amber.shade700;
      case 'IZIN':
        return Colors.blue.shade600;
      case 'ALPA':
        return cs.error;
      default:
        return cs.outline;
    }
  }

  String _statusLabel(String? status) => status ?? 'Belum';

  Future<void> _pickTanggal(BuildContext context) async {
    final provider = context.read<PiketPimpinanProvider>();
    final parsed = DateTime.tryParse(provider.selectedTanggal);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Presensi',
    );
    if (picked == null) return;
    final iso = '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    await provider.loadPresensi(iso);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PiketPimpinanProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Membungkus seluruh Scaffold dengan DefaultTabController agar TabBar terhubung
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Piket Pimpinan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          bottom: TabBar(
            indicatorColor: colorScheme.onPrimary,
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.7),
            tabs: const [
              Tab(text: 'Jadwal Piket', icon: Icon(CupertinoIcons.calendar_badge_plus, size: 18)),
              Tab(text: 'Presensi', icon: Icon(CupertinoIcons.checkmark_shield, size: 18)),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: provider.load,
                child: TabBarView(
                  children: [
                    _buildJadwalTab(context, provider),
                    _buildPresensiTab(context, provider),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildJadwalTab(BuildContext context, PiketPimpinanProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = provider.todayDayName;
    final byDay = provider.dataByDay;
    final terisi = provider.totalTerisi;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.checkmark_seal, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rotasi Piket Pimpinan',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Senin – Ahad · $terisi hari terisi',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < provider.hariList.length; i++) ...[
          _buildDaySection(
            context,
            day: provider.hariList[i],
            short: i < _dayShort.length ? _dayShort[i] : provider.hariList[i],
            isToday: today.toUpperCase() == provider.hariList[i].toUpperCase(),
            items: byDay[provider.hariList[i]] ?? const [],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildDaySection(
    BuildContext context, {
    required String day,
    required String short,
    required bool isToday,
    required List<dynamic> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isToday ? colorScheme.primary : colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  short,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isToday ? colorScheme.onPrimary : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Text(
                    _dayLabel(day),
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HARI INI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (items.isNotEmpty)
              Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                'Belum ada piket',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => _pimpinanChip(context, item)).toList(),
          ),
      ],
    );
  }

  Widget _pimpinanChip(BuildContext context, dynamic item) {
    final colorScheme = Theme.of(context).colorScheme;
    final nama = (item['nama'] ?? '-').toString();
    final jabatan = (item['jabatan'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colorScheme.primaryContainer,
            child: const Icon(CupertinoIcons.person, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nama,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (jabatan.isNotEmpty)
                Text(
                  jabatan,
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiTab(BuildContext context, PiketPimpinanProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final data = provider.presensiData;
    final hari = provider.presensiHari;
    final tanggalLabel = _formatTanggal(provider.selectedTanggal);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _pickTanggal(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(CupertinoIcons.calendar_today, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tanggalLabel,
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                        if (hari.isNotEmpty)
                          Text(
                            'Hari $hari',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  Icon(CupertinoIcons.calendar, size: 18, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (provider.error != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => provider.loadPresensi(provider.selectedTanggal),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
              icon: const Icon(CupertinoIcons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (data.isEmpty && provider.error == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(CupertinoIcons.calendar_badge_minus, size: 36, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text(
                  'Belum ada data presensi piket.',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          for (final item in data)
            _presensiCard(context, item, colorScheme),
      ],
    );
  }

  Widget _presensiCard(BuildContext context, dynamic item, ColorScheme colorScheme) {
    final nama = (item['nama'] ?? '-').toString();
    final jabatan = (item['jabatan'] ?? '').toString();
    final status = item['status']?.toString();
    final keterangan = (item['keterangan'] ?? '').toString();
    final statusColor = _statusColor(status, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: const Icon(CupertinoIcons.person, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  jabatan,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
                if (keterangan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    keterangan,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(String day) {
    const labels = {
      'SENIN': 'Senin',
      'SELASA': 'Selasa',
      'RABU': 'Rabu',
      'KAMIS': 'Kamis',
      'JUMAT': 'Jumat',
      'SABTU': 'Sabtu',
      'AHAD': 'Ahad',
    };
    return labels[day.toUpperCase()] ?? day;
  }

  String _formatTanggal(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    const dayNames = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${dayNames[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }
}