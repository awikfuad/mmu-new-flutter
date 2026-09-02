import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/parent_provider.dart';
import '../../utils/format.dart';
import '../../utils/foto_helper.dart';
import '../../widgets/academic_year_selector.dart';

class ParentChildDetailPage extends StatefulWidget {
  final String nim;
  final String childName;

  const ParentChildDetailPage({
    super.key,
    required this.nim,
    required this.childName,
  });

  @override
  State<ParentChildDetailPage> createState() => _ParentChildDetailPageState();
}

class _ParentChildDetailPageState extends State<ParentChildDetailPage> {
  int? _selectedAcademicYearId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final parentProvider = context.read<ParentProvider>();
    final ayid = _selectedAcademicYearId;

    await Future.wait([
      parentProvider.fetchChildProfile(widget.nim),
      parentProvider.fetchChildKbm(widget.nim, academicYearId: ayid),
      parentProvider.fetchChildPerilaku(widget.nim, academicYearId: ayid),
      parentProvider.fetchChildPrestasi(widget.nim, academicYearId: ayid),
      parentProvider.fetchChildJadwal(widget.nim, academicYearId: ayid),
      parentProvider.fetchChildPembayaran(widget.nim, academicYearId: ayid),
      parentProvider.fetchChildTabungan(widget.nim),
      parentProvider.fetchChildIzinSakit(widget.nim),
      parentProvider.fetchChildPaymentRequests(widget.nim),
      parentProvider.fetchChildKegiatan(widget.nim, academicYearId: ayid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Consumer<ParentProvider>(
        builder: (context, parent, _) {
          if (parent.isLoading && parent.childProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (parent.error != null && parent.childProfile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    Text(
                      parent.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadAllData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = parent.childProfile;

          return RefreshIndicator(
            onRefresh: _loadAllData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // --- 1. Curved Up Collapsible Header ---
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CurvedChildAppBarDelegate(
                    colorScheme: cs,
                    topPadding: topPadding,
                    childName: widget.childName,
                    onBackTap: () => Navigator.pop(context),
                    headerCard: _buildHeaderCardContent(profile, cs),
                    maxExtentHeight: 160.0 + topPadding,
                    minExtentHeight: kToolbarHeight + topPadding,
                  ),
                ),

                // --- 2. Filter Tahun Ajaran ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: AcademicYearSelector(
                      selectedId: _selectedAcademicYearId,
                      compact: true,
                      onChanged: (id) {
                        if (id != _selectedAcademicYearId) {
                          setState(() => _selectedAcademicYearId = id);
                          _loadAllData();
                        }
                      },
                    ),
                  ),
                ),

                // --- 3. Main Menu Grid Content Section ---
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'Menu Informasi Santri',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tampilan Grid Utama
                      _buildMenuGrid(context, parent, cs),
                    ]),
                  ),
                ),

                // --- 4. Footer ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'MMU A-44 \u2022 Portal Orang Tua',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Header Card Content ---
// --- Header Card Content ---
  Widget _buildHeaderCardContent(
    Map<String, dynamic>? profile,
    ColorScheme cs,
  ) {
    final String? fotoUrl = profile?['foto']?.toString();
    final bool hasFoto = fotoUrl != null && fotoUrl.trim().isNotEmpty;
    
    final String rawName = (profile?['name'] ?? widget.childName).toString().trim();
    final String initialName = rawName.isNotEmpty
        ? rawName.substring(0, 1).toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer,
            backgroundImage: hasFoto ? cachedFotoProvider(fotoUrl) : null,
            onBackgroundImageError: hasFoto ? (_, __) {} : null,
            child: !hasFoto
                ? Text(
                    initialName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rawName.isNotEmpty ? rawName : widget.childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIM: ${profile?['nim'] ?? widget.nim}',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Kelas: ${profile?['class_name'] ?? '-'} \u2022 ${(profile?['sumber'] ?? '-').toString().toUpperCase()}',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- Grid Menu Component ---
  Widget _buildMenuGrid(
    BuildContext context,
    ParentProvider parent,
    ColorScheme cs,
  ) {
    final menuItems = [
      _GridMenuItem(
        title: 'Profil',
        icon: Icons.person_outline,
        color: Colors.blue,
        onTap: () =>
            _openBottomSheet('Profil Lengkap', _buildProfileTab(parent, cs)),
      ),
      _GridMenuItem(
        title: 'Absensi KBM',
        icon: Icons.menu_book_outlined,
        color: Colors.orange,
        onTap: () => _openBottomSheet('Riwayat KBM', _buildKbmTab(parent, cs)),
      ),
      _GridMenuItem(
        title: 'Perilaku',
        icon: Icons.psychology_outlined,
        color: Colors.purple,
        onTap: () =>
            _openBottomSheet('Catatan Perilaku', _buildPerilakuTab(parent, cs)),
      ),
      _GridMenuItem(
        title: 'Prestasi',
        icon: Icons.emoji_events_outlined,
        color: Colors.green,
        onTap: () => _openBottomSheet(
          'Prestasi & Pelanggaran',
          _buildPrestasiTab(parent, cs),
        ),
      ),
      _GridMenuItem(
        title: 'Izin / Sakit',
        icon: Icons.medical_information_outlined,
        color: Colors.brown,
        onTap: () => _openBottomSheet(
          'Pengajuan Izin & Sakit',
          _buildIzinSakitTab(parent, cs),
        ),
      ),
      _GridMenuItem(
        title: 'Jadwal',
        icon: Icons.calendar_today_outlined,
        color: Colors.teal,
        onTap: () =>
            _openBottomSheet('Jadwal Pelajaran', _buildJadwalTab(parent, cs)),
      ),
      _GridMenuItem(
        title: 'Keuangan',
        icon: Icons.payments_outlined,
        color: Colors.indigo,
        onTap: () => _openBottomSheet(
          'Keuangan & Tabungan',
          _buildKeuanganTab(parent, cs),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper Modal Bottom Sheet
  void _openBottomSheet(String title, Widget body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: body),
              ],
            );
          },
        );
      },
    );
  }

  // --- Section Tabs / Detail Views ---

  Widget _buildProfileTab(ParentProvider parent, ColorScheme cs) {
    final p = parent.childProfile;
    if (p == null) return const Center(child: Text('Data tidak ditemukan'));

    final jk = (p['jenis_kelamin'] ?? '').toString();
    final jkLabel = jk.isNotEmpty ? (jk == 'L' ? 'Laki-laki' : jk == 'P' ? 'Perempuan' : jk) : '-';
    final tempatLahir = (p['tempat'] ?? '').toString();
    final tglLahir = (p['tanggal_lahir'] ?? '').toString();
    final ttl = tempatLahir.isNotEmpty && tglLahir.isNotEmpty && tglLahir != '-'
        ? '$tempatLahir, $tglLahir'
        : tglLahir.isNotEmpty
            ? tglLahir
            : tempatLahir.isNotEmpty
                ? tempatLahir
                : '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Foto & nama ---
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: cs.primaryContainer,
                backgroundImage: cachedFotoProvider(p['foto']?.toString()),
                onBackgroundImageError: (_, _) {},
                child: p['foto'] == null
                    ? Text(
                        (p['name'] ?? 'S').toString().isEmpty
                            ? 'S'
                            : (p['name'] ?? 'S').toString()[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                p['name'] ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'NIM: ${p['nim'] ?? '-'} \u2022 ${(p['sumber'] ?? '-').toString().toUpperCase()}',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Identitas',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
        ),
        const SizedBox(height: 8),
        _infoRow('Nama', p['name'] ?? '-'),
        _infoRow('NIM', p['nim'] ?? '-'),
        _infoRow('Jenis Kelamin', jkLabel),
        _infoRow('NIK', (p['nik'] ?? '').toString().isNotEmpty ? p['nik'] : '-'),
        _infoRow('Tempat, Tgl Lahir', ttl),
        _infoRow('Tahun Masuk', p['tahun_masuk'] ?? '-'),
        _infoRow('Kelas', p['class_name'] ?? '-'),
        _infoRow('Asal Lembaga', (p['sumber'] ?? '-').toString().toUpperCase()),
        _infoRow('Lembaga Akun', p['account_lembaga'] ?? '-'),
        if ((p['kk'] ?? '').toString().isNotEmpty) _infoRow('No. KK', p['kk']),
        const Divider(height: 24),
        Text(
          'Alamat',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
        ),
        const SizedBox(height: 8),
        if ((p['dusun'] ?? '').toString().isNotEmpty) _infoRow('Dusun', p['dusun']),
        if ((p['desa'] ?? '').toString().isNotEmpty) _infoRow('Desa/Kelurahan', p['desa']),
        if ((p['kecamatan'] ?? '').toString().isNotEmpty) _infoRow('Kecamatan', p['kecamatan']),
        if ((p['kabupaten'] ?? '').toString().isNotEmpty) _infoRow('Kabupaten', p['kabupaten']),
        const Divider(height: 24),
        Text(
          'Data Orang Tua',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
        ),
        const SizedBox(height: 8),
        _infoRow('Ayah', p['nama_ayah'] ?? '-'),
        _infoRow('Pekerjaan Ayah', p['pekerjaan_ayah'] ?? '-'),
        _infoRow('Ibu', p['nama_ibu'] ?? '-'),
        _infoRow('Pekerjaan Ibu', p['pekerjaan_ibu'] ?? '-'),
        if ((p['nama_wali'] ?? '').toString().isNotEmpty) ...[
          _infoRow('Wali', p['nama_wali'] ?? '-'),
          _infoRow('Hubungan', p['hubungan_wali'] ?? '-'),
        ],
        _infoRow('Telepon Wali', p['telepon_wali'] ?? '-'),
        _infoRow('Alamat', p['alamat'] ?? '-'),
      ],
    );
  }

  Widget _buildKbmTab(ParentProvider parent, ColorScheme cs) {
    final data = parent.childKbm;
    if (data.isEmpty) return _emptyState(cs, 'Belum ada data absensi KBM');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final item = data[i];
        final status = item['status'] ?? 'ALPA';
        final color = _statusColor(status, cs);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(_statusIcon(status), color: color, size: 20),
            ),
            title: Text(
              '${item['date']} \u2022 ${item['session_name'] ?? ''}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item['teacher_name'] ?? '-'}\n${item['notes'] ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _statusChip(status, color),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildPerilakuTab(ParentProvider parent, ColorScheme cs) {
    final data = parent.childPerilaku;
    if (data.isEmpty) return _emptyState(cs, 'Belum ada data perilaku');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final item = data[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['tanggal'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _predikatChip('Kerajinan', item['kerajinan'], cs),
                    const SizedBox(width: 6),
                    _predikatChip('Kedisiplinan', item['kedisiplinan'], cs),
                    const SizedBox(width: 6),
                    _predikatChip('Kebersihan', item['kebersihan'], cs),
                  ],
                ),
                if ((item['catatan'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item['catatan'],
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrestasiTab(ParentProvider parent, ColorScheme cs) {
    final data = parent.childPrestasi;
    if (data.isEmpty) {
      return _emptyState(cs, 'Belum ada data prestasi & pelanggaran');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final item = data[i];
        final isPrestasi = item['tipe'] == 'PRESTASI';
        final color = isPrestasi ? Colors.green : Colors.red;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                isPrestasi ? Icons.emoji_events : Icons.gpp_bad,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              item['deskripsi'] ?? '-',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item['kategori'] ?? '-'} \u2022 ${item['tanggal'] ?? '-'}'
              '${item['poin'] != null ? ' \u2022 Poin: ${item['poin']}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJadwalTab(ParentProvider parent, ColorScheme cs) {
    final data = parent.childJadwal;
    if (data.isEmpty) return _emptyState(cs, 'Belum ada data jadwal');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final item = data[i];
        final dayStr = (item['day_of_week'] ?? '?').toString();
        final shortDay = dayStr.length >= 2 ? dayStr.substring(0, 2) : dayStr;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                shortDay,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              item['subject_name'] ?? '-',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item['session_name'] ?? ''} \u2022 ${item['start_time'] ?? ''} - ${item['end_time'] ?? ''}'
              '\nGuru: ${item['guru'] ?? '-'}',
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildKeuanganTab(ParentProvider parent, ColorScheme cs) {
    final tabungan = parent.childTabungan;
    final pembayaran = parent.childPembayaran;
    final paymentRequests = parent.childPaymentRequests;
    final balance = (tabungan?['balance'] ?? 0).toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo Tabungan',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                formatRp(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.request_quote_outlined, size: 20),
            label: const Text(
              'Ajukan Pembayaran dari Tabungan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.tertiary,
              foregroundColor: cs.onTertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _showPaymentRequestForm(cs),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Riwayat Pengajuan',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        if (paymentRequests.isEmpty)
          _emptyState(cs, 'Belum ada pengajuan pembayaran')
        else
          ...paymentRequests.map((item) {
            final status = item['status'] ?? 'MENUNGGU';
            final Color statusColor;
            final IconData statusIcon;
            final String statusLabel;
            switch (status) {
              case 'DISETUJUI':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                statusLabel = 'Disetujui';
                break;
              case 'DITOLAK':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                statusLabel = 'Ditolak';
                break;
              default:
                statusColor = Colors.orange;
                statusIcon = Icons.hourglass_top;
                statusLabel = 'Menunggu';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, size: 18, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${item['payment_type'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nominal: ${formatRp((item['amount'] ?? 0).toDouble())}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item['month'] != null)
                      Text(
                        'Bulan: ${item['month']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (item['admin_notes'] != null)
                      Text(
                        'Catatan admin: ${item['admin_notes']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item['created_at'] ?? ''),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 16),

        Text(
          'Riwayat Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        if (pembayaran.isEmpty)
          _emptyState(cs, 'Belum ada pembayaran')
        else
          ...pembayaran.map((item) {
            final amount = (item['amount'] ?? 0).toDouble();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(
                  '${item['payment_type'] ?? '-'} \u2022 ${item['month'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${formatRp(amount)} \u2022 ${item['payment_method'] ?? '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showPaymentRequestForm(ColorScheme cs) {
    String jenis = 'YAUMIYAH';
    String? bulan;
    final nominalCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final now = DateTime.now();
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ajukan Pembayaran dari Tabungan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'YAUMIYAH',
                        label: Text('Iuran Bulanan'),
                        icon: Icon(Icons.calendar_month, size: 18),
                      ),
                      ButtonSegment(
                        value: 'DAFTAR_ULANG',
                        label: Text('Daftar Ulang'),
                        icon: Icon(Icons.app_registration, size: 18),
                      ),
                    ],
                    selected: {jenis},
                    onSelectionChanged: (sel) =>
                        setModal(() => jenis = sel.first),
                    style: SegmentedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 13),
                      selectedBackgroundColor: jenis == 'YAUMIYAH'
                          ? cs.primary
                          : cs.tertiary,
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (jenis == 'YAUMIYAH') ...[
                    DropdownButtonFormField<String>(
                      initialValue: bulan,
                      decoration: const InputDecoration(
                        labelText: 'Bulan Pembayaran',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: List.generate(12, (i) {
                        final m = ((now.month - 1 + i) % 12) + 1;
                        return DropdownMenuItem(
                          value: '$m/${now.year}',
                          child: Text('$m/${now.year}'),
                        );
                      }),
                      onChanged: (v) => setModal(() => bulan = v),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: nominalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nominal (Rp)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: loading
                          ? null
                          : () async {
                              final nominal = int.tryParse(
                                nominalCtrl.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                              );
                              if (nominal == null || nominal <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nominal tidak valid'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              setModal(() => loading = true);
                              final parentProvider = context.read<ParentProvider>();
                              final ok = await parentProvider.submitPaymentRequest(
                                widget.nim,
                                paymentType: jenis,
                                month: jenis == 'YAUMIYAH' ? bulan : null,
                                amount: nominal,
                              );
                              if (!ctx.mounted) return;
                              setModal(() => loading = false);
                              if (ok) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pengajuan terkirim! Menunggu persetujuan admin.',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      parentProvider.error ??
                                          'Gagal mengirim pengajuan',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kirim Pengajuan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIzinSakitTab(ParentProvider parent, ColorScheme cs) {
    final data = parent.childIzinSakit;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Ajukan Izin / Sakit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showIzinSakitForm(parent, cs),
            ),
          ),
        ),
        Expanded(
          child: data.isEmpty
              ? _emptyState(cs, 'Belum ada pengajuan izin / sakit')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final item = data[i];
                    final jenis = item['jenis'] ?? 'IZIN';
                    final status = item['status'] ?? 'MENUNGGU';
                    final jenisColor = jenis == 'SAKIT'
                        ? Colors.orange
                        : Colors.blue;
                    final statusColor = switch (status) {
                      'DISETUJUI' => Colors.green,
                      'DITOLAK' => Colors.red,
                      _ => Colors.amber.shade700,
                    };
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: jenisColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    jenis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: jenisColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['alasan'] ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['tanggal_mulai'] ?? '-'} s/d ${item['tanggal_selesai'] ?? '-'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            if ((item['keterangan'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Ket: ${item['keterangan']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    status == 'DISETUJUI'
                                        ? Icons.check_circle_outline
                                        : status == 'DITOLAK'
                                        ? Icons.cancel_outlined
                                        : Icons.hourglass_empty_outlined,
                                    size: 16,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      status == 'DISETUJUI'
                                          ? 'Disetujui oleh admin'
                                          : status == 'DITOLAK'
                                          ? 'Ditolak oleh admin'
                                          : 'Menunggu persetujuan admin',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  if ((item['disetujui_oleh'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text(
                                      item['disetujui_oleh'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showIzinSakitForm(ParentProvider parent, ColorScheme cs) {
    String jenis = 'IZIN';
    final alasanCtrl = TextEditingController();
    final keteranganCtrl = TextEditingController();
    DateTime mulai = DateTime.now();
    DateTime selesai = DateTime.now();

    Future<void> pickDate({
      required bool isMulai,
      required StateSetter setModalState,
    }) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: isMulai ? mulai : selesai,
        firstDate: DateTime(2024),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        setModalState(() {
          if (isMulai) {
            mulai = picked;
            if (selesai.isBefore(mulai)) selesai = mulai;
          } else {
            selesai = picked;
            if (mulai.isAfter(selesai)) mulai = selesai;
          }
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final pad = EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          );
          return Padding(
            padding: pad,
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
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ajukan Izin / Sakit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengajuan akan dikirim ke admin untuk persetujuan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'IZIN',
                        label: Text('Izin'),
                        icon: Icon(Icons.event_busy_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: 'SAKIT',
                        label: Text('Sakit'),
                        icon: Icon(Icons.local_hospital_outlined, size: 18),
                      ),
                    ],
                    selected: {jenis},
                    onSelectionChanged: (s) =>
                        setModalState(() => jenis = s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: jenis == 'SAKIT'
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.blue.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    leading: Icon(
                      Icons.calendar_today,
                      color: cs.primary,
                      size: 20,
                    ),
                    title: const Text(
                      'Tanggal Mulai',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${mulai.year}-${mulai.month.toString().padLeft(2, '0')}-${mulai.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () =>
                        pickDate(isMulai: true, setModalState: setModalState),
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    leading: Icon(
                      Icons.calendar_today,
                      color: cs.primary,
                      size: 20,
                    ),
                    title: const Text(
                      'Tanggal Selesai',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${selesai.year}-${selesai.month.toString().padLeft(2, '0')}-${selesai.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () =>
                        pickDate(isMulai: false, setModalState: setModalState),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: alasanCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alasan *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: keteranganCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (opsional)',
                      border: OutlineInputBorder(),
                      hintText: 'Info surat / dokumen pendukung',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final alasan = alasanCtrl.text.trim();
                        if (alasan.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Text('Alasan wajib diisi'),
                              backgroundColor: cs.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        final fmtMulai =
                            '${mulai.year}-${mulai.month.toString().padLeft(2, '0')}-${mulai.day.toString().padLeft(2, '0')}';
                        final fmtSelesai =
                            '${selesai.year}-${selesai.month.toString().padLeft(2, '0')}-${selesai.day.toString().padLeft(2, '0')}';

                        Navigator.pop(ctx);
                        final ok = await parent.submitChildIzinSakit(
                          widget.nim,
                          jenis: jenis,
                          alasan: alasan,
                          tanggalMulai: fmtMulai,
                          tanggalSelesai: fmtSelesai,
                          keterangan: keteranganCtrl.text.trim(),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Pengajuan berhasil dikirim!'
                                    : 'Gagal mengirim pengajuan',
                              ),
                              backgroundColor: ok ? Colors.green : cs.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          if (ok) _loadAllData();
                        }
                      },
                      child: const Text(
                        'Kirim Pengajuan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status, ColorScheme cs) {
    return switch (status) {
      'HADIR' => Colors.green,
      'SAKIT' => Colors.orange,
      'IZIN' => Colors.blue,
      _ => cs.error,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'HADIR' => Icons.check_circle_outline,
      'SAKIT' => Icons.local_hospital_outlined,
      'IZIN' => Icons.info_outline,
      _ => Icons.cancel_outlined,
    };
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _predikatChip(String label, dynamic value, ColorScheme cs) {
    final val = (value ?? '').toString();
    final color = switch (val) {
      'SANGAT_BAIK' => Colors.green,
      'BAIK' => Colors.blue,
      'CUKUP' => Colors.orange,
      'KURANG' => Colors.red,
      _ => cs.onSurface.withValues(alpha: 0.3),
    };
    final display = switch (val) {
      'SANGAT_BAIK' => 'S. Baik',
      'BAIK' => 'Baik',
      'CUKUP' => 'Cukup',
      'KURANG' => 'Kurang',
      _ => '-',
    };
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dt) {
    if (dt.isEmpty) return '-';
    try {
      final d = DateTime.parse(dt);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dt;
    }
  }
}

class _GridMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _GridMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ==========================================
// --- Curved Child AppBar Delegate Class ---
// ==========================================
class _CurvedChildAppBarDelegate extends SliverPersistentHeaderDelegate {
  final ColorScheme colorScheme;
  final double topPadding;
  final String childName;
  final VoidCallback onBackTap;
  final Widget headerCard;
  final double maxExtentHeight;
  final double minExtentHeight;

  _CurvedChildAppBarDelegate({
    required this.colorScheme,
    required this.topPadding,
    required this.childName,
    required this.onBackTap,
    required this.headerCard,
    required this.maxExtentHeight,
    required this.minExtentHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double delta = maxExtentHeight - minExtentHeight;
    final double percent = delta > 0
        ? (shrinkOffset / delta).clamp(0.0, 1.0)
        : 0.0;
    
    // Kedalaman kurva melengkung ke atas
    final double curveDepth = 24.0 * (1.0 - percent);

    return Material(
      elevation: percent > 0.8 ? 2 : 0,
      color: Colors.transparent,
      child: ClipPath(
        clipper: _CurvedUpClipper(curveDepth: curveDepth),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.onPrimary,
                        ),
                        onPressed: onBackTap,
                        tooltip: 'Kembali',
                      ),
                      Expanded(
                        child: Text(
                          childName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Opacity(
                    opacity: (1.0 - (percent * 1.5)).clamp(0.0, 1.0),
                    child: percent > 0.6 ? const SizedBox.shrink() : headerCard,
                  ),
                ),
                // Ruang ekstra bawah untuk lengkungan cekung
                SizedBox(height: curveDepth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxExtentHeight;

  @override
  double get minExtent => minExtentHeight;

  @override
  bool shouldRebuild(covariant _CurvedChildAppBarDelegate oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.maxExtentHeight != maxExtentHeight ||
        oldDelegate.minExtentHeight != minExtentHeight ||
        oldDelegate.childName != childName;
  }
}

// ── Custom Clipper untuk Lengkungan ke Atas (Concave) ──
class _CurvedUpClipper extends CustomClipper<Path> {
  final double curveDepth;

  _CurvedUpClipper({required this.curveDepth});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);

    // Titik kontrol di tengah bagian bawah ditarik ke atas
    final controlPoint = Offset(size.width / 2, size.height - (curveDepth * 2));
    final endPoint = Offset(size.width, size.height);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CurvedUpClipper oldClipper) {
    return oldClipper.curveDepth != curveDepth;
  }
}