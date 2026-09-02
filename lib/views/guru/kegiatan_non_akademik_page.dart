import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kegiatan_list_provider.dart';
import 'presensi_kegiatan_detail_page.dart';
import 'scan_istighosah_page.dart';

class KegiatanNonAkademikPage extends StatefulWidget {
  const KegiatanNonAkademikPage({super.key});

  @override
  State<KegiatanNonAkademikPage> createState() =>
      _KegiatanNonAkademikPageState();
}

class _KegiatanNonAkademikPageState extends State<KegiatanNonAkademikPage> {
  /// Label sasaran peserta dari field `target` backend (v3.6).
  String targetLabel(dynamic target) {
    switch ((target ?? 'SEMUA').toString().toUpperCase()) {
      case 'MURID':
        return 'Murid / Santri';
      case 'GURU':
        return 'Guru / Asatidz';
      default:
        return 'Semua (murid & guru)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // v3.6: hanya kegiatan berasas murid/santri (MURID + SEMUA)
      create: (_) => KegiatanListProvider()..fetchActivities(audience: 'murid'),
      child: Consumer<KegiatanListProvider>(
        builder: (context, provider, _) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Kegiatan Non-Akademik'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: provider.activities.isEmpty
                  ? const Center(
                        child: Text('Belum ada data kegiatan non-akademik.'),
                      )
                  : ListView.builder(
                      itemCount: provider.activities.length,
                      itemBuilder: (context, index) {
                        final activity = provider.activities[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.secondary,
                              child: Icon(Icons.star, color: colorScheme.onPrimary),
                            ),
                            title: Text(
                              activity['activity_name'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tanggal: ${activity['activity_date'] ?? '-'}'),
                                Text('Target: ${targetLabel(activity['target'])}'),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                            onTap: () {
                              final String activityName =
                                  activity['activity_name'] ?? '';

                              if (activityName.toLowerCase().contains(
                                'istighosah',
                              )) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScanIstighosahPage(
                                      activityId: activity['id'],
                                      activityName: activityName,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PresensiKegiatanDetailPage(
                                          activityId: activity['id'],
                                          activityName: activityName,
                                        ),
                                  ),
                                );
                              }
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
