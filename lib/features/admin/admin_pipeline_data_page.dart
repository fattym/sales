import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPipelineDataPage extends StatefulWidget {
  const AdminPipelineDataPage({super.key});

  @override
  State<AdminPipelineDataPage> createState() => _AdminPipelineDataPageState();
}

class _AdminPipelineDataPageState extends State<AdminPipelineDataPage> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  String _stageFilter = 'all';
  List<Map<String, dynamic>> _rows = [];
  Map<String, String> _schoolNamesById = {};
  Map<String, String> _userNamesById = {};

  static const List<String> _stages = [
    'all',
    'lead',
    'contacted',
    'meeting_scheduled',
    'sample_issued',
    'quotation_sent',
    'decision_pending',
    'negotiation',
    'won',
    'lost',
    'dormant',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _normalizeStage(dynamic value) {
    return (value?.toString() ?? '').trim().toLowerCase();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      Future<List<Map<String, dynamic>>> runSalesQuery(String selectClause) async {
        dynamic query = _supabase
            .from('school_sales')
            .select(selectClause)
            .order('updated_at', ascending: false);
        if (_stageFilter != 'all') {
          query = query.eq('sale_status', _stageFilter.trim().toLowerCase());
        }
        final res = await query;
        var rows = List<Map<String, dynamic>>.from(
          (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        // Defensive local filter in case DB values have inconsistent casing/spacing.
        if (_stageFilter != 'all') {
          final wanted = _stageFilter.trim().toLowerCase();
          rows =
              rows.where((row) => _normalizeStage(row['sale_status']) == wanted).toList();
        }
        return rows;
      }

      List<Map<String, dynamic>> rows;
      try {
        rows = await runSalesQuery('''
          id,
          school_id,
          agent_id,
          package_name,
          expected_value,
          sale_status,
          probability,
          expected_close_date,
          stage_contact_person,
          sample_quantity,
          quotation_reference,
          decision_owner,
          negotiation_topic,
          loss_reason,
          dormant_reason,
          created_at
        ''');
      } catch (_) {
        // Fallback for environments where latest stage-detail columns are not yet migrated.
        rows = await runSalesQuery('''
          id,
          school_id,
          agent_id,
          package_name,
          expected_value,
          sale_status,
          probability,
          expected_close_date,
          created_at
        ''');
      }

      final schoolIds =
          rows
              .map((r) => r['school_id']?.toString())
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
      final userIds =
          rows
              .map((r) => r['agent_id']?.toString())
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

      final schoolNamesById = <String, String>{};
      if (schoolIds.isNotEmpty) {
        try {
          final schoolRows = await _supabase
              .from('schools')
              .select('id,name')
              .filter('id', 'in', '(${schoolIds.map((e) => '"$e"').join(',')})');
          for (final item in schoolRows as List) {
            final map = Map<String, dynamic>.from(item as Map);
            schoolNamesById[map['id'].toString()] =
                map['name']?.toString() ?? '-';
          }
        } catch (_) {
          // Keep rendering pipeline rows even if school lookup fails.
        }
      }

      final userNamesById = <String, String>{};
      if (userIds.isNotEmpty) {
        try {
          final userRows = await _supabase
              .from('users')
              .select('id,full_name,email')
              .filter('id', 'in', '(${userIds.map((e) => '"$e"').join(',')})');
          for (final item in userRows as List) {
            final map = Map<String, dynamic>.from(item as Map);
            userNamesById[map['id'].toString()] =
                map['full_name']?.toString() ?? map['email']?.toString() ?? '-';
          }
        } catch (_) {
          // Keep rendering pipeline rows even if user lookup fails.
        }
      }

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _schoolNamesById = schoolNamesById;
        _userNamesById = userNamesById;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Failed to load pipeline data. Details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline Data'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Stage:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _stageFilter,
                    items: _stages
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s == 'all'
                                  ? 'All'
                                  : s.replaceAll('_', ' ').toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _stageFilter = value);
                      _load();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                  ? const Center(child: Text('No pipeline data found.'))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final school =
                            _schoolNamesById[row['school_id']?.toString()] ??
                            'Unknown';
                        final owner =
                            _userNamesById[row['agent_id']?.toString()] ?? '-';
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$school • ${row['sale_status'] ?? '-'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text('Package: ${row['package_name'] ?? '-'}'),
                                Text('Owner: $owner'),
                                Text('Value: KES ${(row['expected_value'] ?? 0).toString()}'),
                                Text('Probability: ${(row['probability'] ?? 0)}%'),
                                if (row['stage_contact_person'] != null)
                                  Text('Contact Person: ${row['stage_contact_person']}'),
                                if (row['sample_quantity'] != null)
                                  Text('Sample Qty: ${row['sample_quantity']}'),
                                if (row['quotation_reference'] != null)
                                  Text('Quote Ref: ${row['quotation_reference']}'),
                                if (row['decision_owner'] != null)
                                  Text('Decision Owner: ${row['decision_owner']}'),
                                if (row['negotiation_topic'] != null)
                                  Text('Negotiation: ${row['negotiation_topic']}'),
                                if (row['loss_reason'] != null)
                                  Text('Loss Reason: ${row['loss_reason']}'),
                                if (row['dormant_reason'] != null)
                                  Text('Dormant Reason: ${row['dormant_reason']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
