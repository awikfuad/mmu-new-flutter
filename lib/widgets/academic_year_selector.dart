import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../data/api/api_service.dart';

class AcademicYear {
  final int id;
  final String yearName;
  final String semester;
  final bool isActive;

  AcademicYear({required this.id, required this.yearName, required this.semester, required this.isActive});

  factory AcademicYear.fromJson(Map<String, dynamic> j) {
    return AcademicYear(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id'] ?? 0}') ?? 0,
      yearName: '${j['year_name'] ?? '-'}',
      semester: '${j['semester'] ?? '-'}',
      isActive: j['is_active'] == 1 || j['is_active'] == true,
    );
  }

  String get display => '$yearName ($semester)';
}

/// Reusable dropdown button for academic year selection.
/// Usage: AcademicYearSelector(selectedId: ..., onChanged: ...)
class AcademicYearSelector extends StatefulWidget {
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool compact;

  const AcademicYearSelector({
    super.key,
    this.selectedId,
    required this.onChanged,
    this.compact = false,
  });

  @override
  State<AcademicYearSelector> createState() => _AcademicYearSelectorState();
}

class _AcademicYearSelectorState extends State<AcademicYearSelector> {
  final ApiService _api = ApiService();
  List<AcademicYear> _years = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
  try {
    final res = await _api.dio.get('/academic-years');

    // 💡 CEK MOUNTED SETELAH AWAIT
    if (!mounted) return;

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List)
          .map((j) => AcademicYear.fromJson(j))
          .toList();

      setState(() {
        _years = list;
        _loading = false;
      });

      // Auto-select active year if nothing selected
      if (widget.selectedId == null && list.isNotEmpty) {
        final active = list.where((y) => y.isActive).toList();
        if (active.isNotEmpty) {
          widget.onChanged(active.first.id);
        }
      }
    }
  } on DioException catch (_) {
    if (!mounted) return;
    setState(() => _loading = false);
  } catch (_) {
    if (!mounted) return;
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 36,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_years.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<int>(
      initialValue: widget.selectedId,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Tahun Ajaran',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: widget.compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: _years.map((y) {
        return DropdownMenuItem(
          value: y.id,
          child: Row(
            children: [
              if (y.isActive)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('AKTIF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              Expanded(child: Text(y.display, style: const TextStyle(fontSize: 13))),
            ],
          ),
        );
      }).toList(),
      onChanged: widget.onChanged,
    );
  }
}
