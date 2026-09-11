import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kegiatan_list_provider.dart';
import 'presensi_kegiatan_guru_detail_page.dart';

class KegiatanInternalGuruPage extends StatefulWidget {
  const KegiatanInternalGuruPage({super.key});

  @override
  State<KegiatanInternalGuruPage> createState() => _KegiatanInternalGuruPageState();
}

class _KegiatanInternalGuruPageState extends State<KegiatanInternalGuruPage> {
  /// Label sasaran peserta dari field `target` backend (v3.6).
  String targetLabel(dynamic target) {
    switch ((target ?? 'SEMUA').toString().toUpperCase()) {
      case 'GURU':
        return 'Target: Khusus Asatidz / Guru';
      case 'MURID':
        return 'Target: Khusus Murid / Santri';
      default:
        return 'Target: Semua (murid & guru)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // v3.6: hanya kegiatan berasas guru/asatidz (GURU + SEMUA)
      create: (_) => KegiatanListProvider()..fetchActivities(audience: 'guru'),
      child: Consumer<KegiatanListProvider>(
        builder: (context, provider, _) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Kegiatan Internal Guru'),
         backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: provider.activities.isEmpty
                  ? const Center(child: Text('Belum ada agenda kegiatan internal guru.'))
                  : ListView.builder(
                      itemCount: provider.activities.length,
                      itemBuilder: (context, index) {
                        final activity = provider.activities[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.tertiary,
                              child: Icon(Icons.co_present, color: colorScheme.onPrimary),
                            ),
                            title: Text(
                              activity['activity_name'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(targetLabel(activity['target'])),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.tertiary),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PresensiKegiatanGuruDetailPage(
                                    activityId: activity['id'] as int? ?? 0,
                                    activityName: (activity['activity_name'] ?? '').toString(),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}
