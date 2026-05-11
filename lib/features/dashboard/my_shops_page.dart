import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../database/database_service.dart';
import '../../models/farmer_model.dart';
import 'agrovet_onboarding.dart';
import 'school_action_menu_page.dart';

class MyShopsPage extends StatefulWidget {
  const MyShopsPage({super.key});

  @override
  State<MyShopsPage> createState() => _MyShopsPageState();
}

class _MyShopsPageState extends State<MyShopsPage> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<SchoolModel>> _schoolsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _schoolsFuture = _dbService.getAllSchools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshSchools() async {
    setState(() {
      _schoolsFuture = _dbService.getAllSchools();
    });
  }

  List<SchoolModel> _filterSchools(List<SchoolModel> schools) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return schools;
    return schools.where((school) {
      return school.name.toLowerCase().contains(q) ||
          school.county.toLowerCase().contains(q) ||
          (school.bookCategory ?? '').toLowerCase().contains(q) ||
          school.focusAreas.any((area) => area.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      appBar: AppBar(
        title: const Text('My Schools'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSchools,
          ),
        ],
      ),
      body: FutureBuilder<List<SchoolModel>>(
        future: _schoolsFuture,
        builder: (context, snapshot) {
          final schools = _filterSchools(snapshot.data ?? const <SchoolModel>[]);

          return RefreshIndicator(
            onRefresh: _refreshSchools,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load schools: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (schools.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No schools found. Try onboarding one.'),
                    ),
                  )
                else
                  ...schools.map(_buildSchoolCard),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add_business, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SchoolOnboarding()),
          ).then((_) => _refreshSchools());
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primaryGreen,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by school, county, or book category...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolCard(SchoolModel school) {
    final nextAction = _deriveAction(school);
    final focusAreas = school.focusAreas;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolActionMenuPage(
                school: {
                  'id': school.id,
                  'name': school.name,
                  'phone': school.phone,
                  'county': school.county,
                  'focusAreas': school.focusAreas,
                  'book_category': school.bookCategory,
                  'latitude': school.latitude,
                  'longitude': school.longitude,
                  'photo_url': school.photoUrl,
                  'photo_path': school.photoPath,
                  'captured_by': school.capturedBy,
                  'captured_at': school.capturedAt?.toIso8601String(),
                  'capture_status': school.captureStatus,
                  'isSynced': school.isSynced,
                  'created_at': school.createdAt?.toIso8601String(),
                  'updated_at': school.updatedAt?.toIso8601String(),
                  'nextAction': nextAction,
                },
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (school.photoUrl != null && school.photoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: Image.network(
                    school.photoUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primaryGreen.withOpacity(0.08),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.school_outlined,
                          color: AppColors.primaryGreen,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                      child: const Icon(Icons.school_outlined, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        school.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (school.photoUrl != null && school.photoUrl!.isNotEmpty)
                    Text(
                      school.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${school.county} • ${school.phone}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Book', school.bookCategory ?? 'None'),
                      _chip('Sync', school.isSynced ? 'Synced' : 'Pending'),
                      _chip(
                        'Capture',
                        school.captureStatus ?? 'Not captured',
                      ),
                      _chip('Next', nextAction),
                    ],
                  ),
                  if (focusAreas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Focus areas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: focusAreas
                          .take(3)
                          .map((area) => _chip('Area', area))
                          .toList(),
                    ),
                  ],
                  if (school.latitude != null && school.longitude != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Location: ${school.latitude!.toStringAsFixed(4)}, ${school.longitude!.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _deriveAction(SchoolModel school) {
    if ((school.bookCategory ?? '').toLowerCase() == 'book fund') {
      return 'Sell';
    }
    if (school.focusAreas.isNotEmpty) {
      return 'Follow Up';
    }
    return 'Visit';
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
