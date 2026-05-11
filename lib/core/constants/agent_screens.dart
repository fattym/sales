import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'colors.dart';
import '../../features/dashboard/school_sell_page.dart';

class AgentRoutePlanScreen extends StatefulWidget {
  const AgentRoutePlanScreen({super.key});

  @override
  State<AgentRoutePlanScreen> createState() => _AgentRoutePlanScreenState();
}

class _AgentRoutePlanScreenState extends State<AgentRoutePlanScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _routePlans = [];

  @override
  void initState() {
    super.initState();
    _fetchRoutePlans();
  }

  Future<void> _fetchRoutePlans() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('route_plans')
          .select()
          .eq('assigned_to', userId)
          .order('route_date', ascending: true);

      setState(() {
        _routePlans = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading route plans: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Route Plan'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.surfaceWhite,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _routePlans.isEmpty
              ? const Center(child: Text('No route plans assigned to you.'))
              : ListView.builder(
                itemCount: _routePlans.length,
                itemBuilder: (context, index) {
                  final plan = _routePlans[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: AppColors.surfaceWhite,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryPale,
                        child: Icon(
                          Icons.directions_car,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      title: Text(
                        plan['title'] ?? 'Route Plan',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Date: ${plan['route_date']} \nStatus: ${plan['status']} \nNotes: ${plan['notes'] ?? 'None'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }
}

class AgentSchoolVisitsScreen extends StatefulWidget {
  const AgentSchoolVisitsScreen({super.key});

  @override
  State<AgentSchoolVisitsScreen> createState() =>
      _AgentSchoolVisitsScreenState();
}

class _AgentSchoolVisitsScreenState extends State<AgentSchoolVisitsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _visits = [];

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('school_visits')
          .select('*, schools(name)')
          .eq('agent_id', userId)
          .order('visited_at', ascending: false);

      setState(() {
        _visits = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading visits: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Visits'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.surfaceWhite,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _visits.isEmpty
              ? const Center(child: Text('No visits recorded.'))
              : ListView.builder(
                itemCount: _visits.length,
                itemBuilder: (context, index) {
                  final visit = _visits[index];
                  final schoolName =
                      visit['schools']?['name'] ?? 'Unknown School';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: AppColors.surfaceWhite,
                    child: ListTile(
                      leading: const Icon(
                        Icons.school_outlined,
                        color: AppColors.infoBlue,
                        size: 36,
                      ),
                      title: Text(
                        schoolName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Outcome: ${visit['outcome'] ?? 'N/A'}\nNotes: ${visit['notes'] ?? ''}',
                      ),
                      trailing: Text(
                        visit['visit_status']?.toString().toUpperCase() ?? '',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }
}

class AgentSubmitOrderScreen extends StatefulWidget {
  const AgentSubmitOrderScreen({super.key});

  @override
  State<AgentSubmitOrderScreen> createState() => _AgentSubmitOrderScreenState();
}

class _AgentSubmitOrderScreenState extends State<AgentSubmitOrderScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schools = [];

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    try {
      final response = await Supabase.instance.client
          .from('schools')
          .select()
          .order('name');

      setState(() {
        _schools = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schools: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select School for Order'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.surfaceWhite,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _schools.isEmpty
              ? const Center(child: Text('No schools available.'))
              : ListView.builder(
                itemCount: _schools.length,
                itemBuilder: (context, index) {
                  final school = _schools[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryPale,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    title: Text(
                      school['name'] ?? 'Unknown School',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(school['county'] ?? 'Unknown County'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SchoolSellPage(school: school),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}

class AgentDistributeSamplesScreen extends StatefulWidget {
  const AgentDistributeSamplesScreen({super.key});

  @override
  State<AgentDistributeSamplesScreen> createState() =>
      _AgentDistributeSamplesScreenState();
}

class _AgentDistributeSamplesScreenState
    extends State<AgentDistributeSamplesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _samples = [];

  @override
  void initState() {
    super.initState();
    _fetchSamples();
  }

  Future<void> _fetchSamples() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('school_sample_distributions')
          .select('*, schools(name)')
          .eq('agent_id', userId)
          .order('distributed_at', ascending: false);

      setState(() {
        _samples = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading samples: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distributed Samples'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.surfaceWhite,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _samples.isEmpty
              ? const Center(child: Text('No samples distributed yet.'))
              : ListView.builder(
                itemCount: _samples.length,
                itemBuilder: (context, index) {
                  final sample = _samples[index];
                  final schoolName =
                      sample['schools']?['name'] ?? 'Unknown School';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: AppColors.surfaceWhite,
                    child: ListTile(
                      leading: const Icon(
                        Icons.menu_book,
                        color: AppColors.softGold,
                        size: 36,
                      ),
                      title: Text(
                        sample['sample_name'] ?? 'Sample',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'School: $schoolName\nQty Distributed: ${sample['quantity']}\nNotes: ${sample['notes']}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }
}
