import 'package:flutter/material.dart';
import '../data/api/api_service.dart';
import '../utils/foto_helper.dart';

/// Membuka bottom sheet untuk memilih santri/murid dari /muridKelas.
/// Mengembalikan Map murid terpilih (id, name, nim, class_name, ...) atau null bila dibatalkan.
Future<Map<String, dynamic>?> showMuridPicker(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _MuridPickerSheet(),
  );
}

class _MuridPickerSheet extends StatefulWidget {
  const _MuridPickerSheet();

  @override
  State<_MuridPickerSheet> createState() => _MuridPickerSheetState();
}

class _MuridPickerSheetState extends State<_MuridPickerSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _allMurid = [];
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetchMuridList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMuridList() async {
    try {
      final response = await _apiService.dio.get('/muridKelas');
      if (!mounted) return;
      setState(() {
        _allMurid = response.data['data'] ?? [];
        _filtered = _allMurid;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat daftar murid: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allMurid
          : _allMurid
              .where((m) =>
                  (m['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (m['nim'] ?? '').toString().toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Pilih Santri',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIM santri...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Santri tidak ditemukan.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final m = _filtered[index];
                          final fotoUrl = resolveFotoUrl(m['foto']?.toString());
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundImage: cachedFotoProvider(fotoUrl),
                              onBackgroundImageError: (_, __) {},
                              child: fotoUrl == null
                                  ? Icon(
                                      Icons.person_outline_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                            ),
                            title: Text(
                              m['name'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'NIM: ${m['nim'] ?? '-'}${m['class_name'] != null ? '  •  ${m['class_name']}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () =>
                                Navigator.pop(context, m as Map<String, dynamic>),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
