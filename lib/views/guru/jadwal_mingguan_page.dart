import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jadwal_mingguan_provider.dart';

class JadwalMingguanPage extends StatelessWidget {
  const JadwalMingguanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JadwalMingguanProvider()..load(),
      child: const _JadwalMingguanBody(),
    );
  }
}

class _JadwalMingguanBody extends StatelessWidget {
  const _JadwalMingguanBody();

  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Senin pada pekan berjalan (awal urutan pekan SENIN→AHAD).
  DateTime _weekMonday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  String _todayName() {
    const days = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'AHAD'];
    return days[DateTime.now().weekday - 1];
  }

  String _dateLabel(DateTime monday, int index) {
    final d = monday.add(Duration(days: index));
    return '${d.day} ${_monthsShort[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JadwalMingguanProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final grouped = provider.groupedByDay;
    final monday = _weekMonday();
    final todayName = _todayName();
    final total = provider.schedules.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jadwal Sepekan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              provider.isAdmin && provider.selectedTeacherName.isNotEmpty
                  ? 'Jadwal: ${provider.selectedTeacherName}'
                  : 'Jadwal mengajar seminggu ($total sesi)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
         backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.load(teacherId: provider.selectedTeacherId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (provider.isAdmin) _buildTeacherPicker(context, provider),
                  if (provider.error != null)
                    _buildError(colorScheme, provider.error!)
                  else if (total == 0)
                    _buildEmpty(colorScheme)
                  else
                    ...JadwalMingguanProvider.dayOrder
                        .where((d) => grouped.containsKey(d))
                        .map((d) => _buildDaySection(
                            context,
                            d,
                            _dateLabel(monday, JadwalMingguanProvider.dayOrder.indexOf(d)),
                            grouped[d]!,
                            d == todayName,
                            provider.isAdmin,
                            colorScheme,
                            Theme.of(context))),
                ],
              ),
            ),
    );
  }

  Widget _buildTeacherPicker(BuildContext context, JadwalMingguanProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_search_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: provider.selectedTeacherId,
                hint: const Text('Pilih guru...', style: TextStyle(fontSize: 13)),
                items: provider.teachers
                    .map((t) => DropdownMenuItem<int>(
                          value: int.tryParse('${t['id']}'),
                          child: Text(
                            (t['name'] ?? '-').toString(),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (id) => provider.selectTeacher(id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    String day,
    String dateLabel,
    List<dynamic> items,
    bool isToday,
    bool isAdmin,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final accent = isToday ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isToday ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• $dateLabel',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
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
                const SizedBox(width: 8),
                Text(
                  '${items.length} sesi',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ...items.map((s) => _buildScheduleItem(s, isAdmin, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(dynamic s, bool isAdmin, ColorScheme colorScheme) {
    final isPiket = (s['teaching_status'] ?? '').toString().toUpperCase() == 'PIKET';
    final accent = isPiket ? colorScheme.tertiary : colorScheme.primary;
    final subject = (s['subject_name'] ?? '-').toString();
    final className = (s['class_name'] ?? '-').toString();
    final session = (s['session_name'] ?? '').toString();
    final startTime = (s['start_time'] ?? '').toString();
    final endTime = (s['end_time'] ?? '').toString();
    final rombel = (s['rombel_id'] ==1 ? 'Putra': 'Putri').toString();
    final mainTeacher = (s['main_teacher_name'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(startTime,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                Text('–',
                    style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                Text(endTime,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$className- $rombel-${session.isNotEmpty ? ' · $session' : ''}',
                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAdmin && mainTeacher.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    isPiket ? 'Badal dari $mainTeacher' : 'Guru: $mainTeacher',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPiket ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPiket ? 'PIKET' : 'UTAMA',
              style: TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined,
              size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            'Belum ada jadwal mengajar pekan ini.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
