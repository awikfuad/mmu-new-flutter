import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/input_nilai_provider.dart';

class InputNilaiHarianPage extends StatelessWidget {
  final int scheduleId;
  final int classroomId;
  final String subjectName;
  final String className;
  final String tanggal;
  final int? subjectId;
  final int? jenjangId;
  final int? rombelId;
  final int? academicYearId;

  const InputNilaiHarianPage({
    super.key,
    required this.scheduleId,
    required this.classroomId,
    required this.subjectName,
    required this.className,
    required this.tanggal,
    this.subjectId,
    this.jenjangId,
    this.rombelId,
    this.academicYearId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InputNilaiProvider()
        ..fetchStudents(
          classroomId: classroomId,
          subjectId: subjectId ?? 0,
          tanggal: tanggal,
          rombelId: rombelId,
          academicYearId: academicYearId,
        ),
      child: _InputNilaiBody(
        scheduleId: scheduleId,
        classroomId: classroomId,
        subjectName: subjectName,
        className: className,
        tanggal: tanggal,
        subjectId: subjectId ?? 0,
        jenjangId: jenjangId,
        rombelId: rombelId,
        academicYearId: academicYearId,
      ),
    );
  }
}

class _InputNilaiBody extends StatelessWidget {
  final int scheduleId;
  final int classroomId;
  final String subjectName;
  final String className;
  final String tanggal;
  final int subjectId;
  final int? jenjangId;
  final int? rombelId;
  final int? academicYearId;

  const _InputNilaiBody({
    required this.scheduleId,
    required this.classroomId,
    required this.subjectName,
    required this.className,
    required this.tanggal,
    required this.subjectId,
    this.jenjangId,
    this.rombelId,
    this.academicYearId,
  });

  String _formatTanggal(String tgl) {
    try {
      final parts = tgl.split('-');
      if (parts.length != 3) return tgl;
      final months = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final day = int.tryParse(parts[2]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;
      final year = parts[0];
      return '$day ${months[month]} $year';
    } catch (_) {
      return tgl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<InputNilaiProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subjectName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Kelas: $className · ${_formatTanggal(tanggal)}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: colorScheme.error.withAlpha(153)),
                      const SizedBox(height: 8),
                      Text(provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Ringkasan
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      color: colorScheme.surfaceContainerLow,
                      child: Row(
                        children: [
                          _infoChip(
                              'Total', provider.totalCount, colorScheme.primary),
                          const SizedBox(width: 8),
                          _infoChip(
                              'Sudah',
                              provider.sudahCount,
                              provider.sudahCount > 0
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600),
                          const SizedBox(width: 8),
                          if (provider.changedCount > 0)
                            _infoChip(
                                'Ubah',
                                provider.changedCount,
                                Colors.amber.shade700),
                          const Spacer(),
                          if (provider.successMessage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.green.withAlpha(76)),
                              ),
                              child: Text(
                                provider.successMessage!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nama Murid / Santri',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Nilai',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Roster
                    Expanded(
                      child: provider.students.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada murid aktif di kelas ini.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          : ListView.builder(
                              itemCount: provider.students.length,
                              itemBuilder: (context, index) {
                                final student = provider.students[index];
                                final nim = student['nim']?.toString() ?? '';
                                final name = student['name'] ?? '-';
                                final currentNilai =
                                    provider.nilai[nim] ?? 0;
                                final prevNilai =
                                    provider.previousNilai[nim];

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          colorScheme.outlineVariant.withAlpha(128),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    child: Row(
                                      children: [
                                        // Info murid
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              colorScheme.primaryContainer,
                                          child: Text(
                                            (name.isNotEmpty
                                                    ? name[0]
                                                    : '?')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                nim,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Input nilai
                                        SizedBox(
                                          width: 80,
                                          child: TextFormField(
                                            initialValue: prevNilai != null
                                                ? currentNilai.toInt().toString()
                                                : '',
                                            keyboardType:
                                                TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(3),
                                            ],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(
                                              hintText: '0',
                                              hintStyle: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant
                                                      .withAlpha(102)),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: colorScheme
                                                        .outlineVariant),
                                              ),
                                              focusedBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: colorScheme
                                                        .primary,
                                                    width: 2),
                                              ),
                                              filled: true,
                                              fillColor: colorScheme
                                                  .surfaceContainerHigh,
                                            ),
                                            onChanged: (val) {
                                              final numVal =
                                                  double.tryParse(val) ?? 0;
                                              provider.setNilai(nim, numVal);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Tombol Simpan
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                            top: BorderSide(
                                color: colorScheme.outlineVariant
                                    .withAlpha(76))),
                      ),
                      child: ElevatedButton(
                        onPressed: provider.isSaving
                            ? null
                            : () async {
                                final saved = await provider.submitNilai(
                                  scheduleId: scheduleId,
                                  subjectId: subjectId,
                                  tanggal: tanggal,
                                  classroomId: classroomId,
                                  jenjangId: jenjangId,
                                  rombelId: rombelId,
                                  academicYearId: academicYearId,
                                );
                                if (!context.mounted) return;
                                final prov = context.read<InputNilaiProvider>();
                                String msg = prov.successMessage ?? 'Berhasil.';
                                if (prov.error != null) msg = prov.error!;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(msg),
                                    backgroundColor: prov.error != null
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                  ),
                                );
                                if (saved > 0) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: provider.isSaving
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: colorScheme.onPrimary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'SIMPAN NILAI (${provider.changedCount} ubah)',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    )
                  ],
                ),
    );
  }

  Widget _infoChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
