import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../database/database_service.dart';
import '../../../models/farmer_model.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';
import 'catalog_import_page.dart';
import '../profile/messages_page.dart';
import '../welcome/auth/login_page.dart';
import 'users_list_page.dart';
import 'assign_books_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final DatabaseService _dbService = DatabaseService();
  late Future<_AdminDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_AdminDashboardData> _loadDashboard() async {
    final users = await _dbService.getAllUsers();
    final schools = await _dbService.getAllSchools();
    final tasks = await _dbService.getAllTasks();
    return _AdminDashboardData(users: users, schools: schools, tasks: tasks);
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  Future<void> _updateRole(UserModel user, int role) async {
    try {
      await _dbService.updateUserRole(user.id, role);
      _refreshDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.email} updated to role $role'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DeHeusLogin()),
      (route) => false,
    );
  }

  Future<void> _createTask() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final roleController = TextEditingController(text: '2');
    DateTime? dueDate;

    try {
      if (!mounted) return;
      final created = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> pickDate() async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dueDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setDialogState(() => dueDate = picked);
                }
              }

              return AlertDialog(
                title: const Text('Create Task'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task title',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: roleController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target role',
                          helperText: 'Use 0 for all users, or 1, 2, 3, 4...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dueDate == null
                                  ? 'Due date: optional'
                                  : 'Due date: ${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                          TextButton(
                            onPressed: pickDate,
                            child: const Text('Pick date'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (created != true) return;

      final title = titleController.text.trim();
      final description = descriptionController.text.trim();
      final targetRole = int.tryParse(roleController.text.trim()) ?? 2;

      if (title.isEmpty || description.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Title and description are required.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      await _dbService.createTask(
        TaskModel(
          title: title,
          description: description,
          targetRole: targetRole,
          dueAt: dueDate,
          createdBy: currentUser?.id,
        ),
      );

      _refreshDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      roleController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: _createTask,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
          ),
          if (!isDesktop)
            IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(context)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: FutureBuilder<_AdminDashboardData>(
              future: _dashboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load dashboard: ${snapshot.error}'),
                  );
                }

                final data =
                    snapshot.data ??
                    const _AdminDashboardData(
                      users: <UserModel>[],
                      schools: <SchoolModel>[],
                      tasks: <TaskModel>[],
                    );

                return RefreshIndicator(
                  onRefresh: () async => _refreshDashboard(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 20),
                      _buildSchoolsMap(data.schools),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        "Tasks",
                        subtitle:
                            "Create and review tasks assigned to specific roles.",
                      ),
                      const SizedBox(height: 12),
                      if (data.tasks.isEmpty)
                        _buildEmptyCard("No tasks created yet.")
                      else
                        ...data.tasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TaskCard(task: task),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        "User Access Control",
                        subtitle:
                            "Promote or demote users directly from Supabase-backed records.",
                      ),
                      const SizedBox(height: 12),
                      if (data.users.isEmpty)
                        _buildEmptyCard("No users found yet.")
                      else
                        ...data.users.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UserRoleCard(
                              user: user,
                              onRoleChanged: (role) => _updateRole(user, role),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.longhornMaroon,
            AppColors.charcoalGrey.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text(
            "Admin Controls",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Review users and view school GPS dots on the map.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            "Use the + button to add role-based tasks.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalGrey,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey[700])),
        ],
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.primaryDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            width: double.infinity,
            color: AppColors.charcoalGrey.withValues(alpha: 0.2),
            child: const SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Admin Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Publisher Controls',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem(context, Icons.dashboard, 'Dashboard', () {
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                }),
                _buildSidebarItem(
                  context,
                  Icons.upload_file,
                  'Import Catalog',
                  () async {
                    if (MediaQuery.of(context).size.width < 800) {
                      Navigator.pop(context);
                    }
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CatalogImportPage(),
                      ),
                    );
                    _refreshDashboard();
                  },
                ),
                _buildSidebarItem(
                  context,
                  Icons.chat_bubble_outline,
                  'Messages',
                  () {
                    if (MediaQuery.of(context).size.width < 800) {
                      Navigator.pop(context);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagesPage(),
                      ),
                    );
                  },
                ),
                _buildSidebarItem(
                  context,
                  Icons.people_outline,
                  'Team Directory',
                  () {
                    if (MediaQuery.of(context).size.width < 800) {
                      Navigator.pop(context);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsersListPage(),
                      ),
                    );
                  },
                ),
                _buildSidebarItem(
                  context,
                  Icons.local_shipping_outlined,
                  'Assign Delivery',
                  () {
                    if (MediaQuery.of(context).size.width < 800) {
                      Navigator.pop(context);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignBooksPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSidebarItem(
                context,
                Icons.logout,
                'Sign Out',
                _signOut,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      hoverColor: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildSchoolsMap(List<SchoolModel> schools) {
    final validSchools =
        schools
            .where(
              (school) => school.latitude != null && school.longitude != null,
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "School GPS Map",
          subtitle: "Dots represent schools with saved latitude and longitude.",
        ),
        const SizedBox(height: 12),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child:
              validSchools.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No school GPS coordinates found yet.\nSave a school profile to see dots here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  )
                  : FlutterMap(
                    options: MapOptions(
                      initialCenter: _mapCenter(validSchools),
                      initialZoom: validSchools.length > 1 ? 6.3 : 11.5,
                      minZoom: 2,
                      maxZoom: 18,
                      backgroundColor: const Color(0xFFE9EFE8),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'dehus.longhorn.publishers',
                      ),
                      MarkerLayer(markers: _schoolMarkers(validSchools)),
                    ],
                  ),
        ),
      ],
    );
  }

  LatLng _mapCenter(List<SchoolModel> schools) {
    if (schools.isEmpty) {
      return const LatLng(-1.286389, 36.817223);
    }

    final latitudes = schools
        .map((school) => school.latitude!)
        .toList(growable: false);
    final longitudes = schools
        .map((school) => school.longitude!)
        .toList(growable: false);
    final avgLat = latitudes.reduce((a, b) => a + b) / latitudes.length;
    final avgLng = longitudes.reduce((a, b) => a + b) / longitudes.length;
    return LatLng(avgLat, avgLng);
  }

  List<Marker> _schoolMarkers(List<SchoolModel> schools) {
    return schools
        .where((school) => school.latitude != null && school.longitude != null)
        .map(
          (school) => Marker(
            point: LatLng(school.latitude!, school.longitude!),
            width: 34,
            height: 34,
            child: Tooltip(
              message: school.name,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.longhornMaroon.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.longhornMaroon.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

class _UserRoleCard extends StatelessWidget {
  const _UserRoleCard({required this.user, required this.onRoleChanged});

  final UserModel user;
  final ValueChanged<int> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 1;
    final roleValue = user.role;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.longhornMaroon.withValues(
                  alpha: 0.12,
                ),
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.longhornMaroon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName?.isNotEmpty == true
                          ? user.fullName!
                          : user.email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(color: Colors.grey[700])),
                    if (user.phone?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.phone!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              Chip(
                label: Text(
                  'Role $roleValue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor:
                    isAdmin
                        ? AppColors.longhornMaroon
                        : AppColors.sageGreyGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: user.role,
                  decoration: InputDecoration(
                    labelText: 'Role ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - Admin')),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('2 - Sales Manager'),
                    ),
                    DropdownMenuItem(value: 3, child: Text('3 - BAS')),
                    DropdownMenuItem(value: 4, child: Text('4 - Agent')),
                    DropdownMenuItem(
                      value: 5,
                      child: Text('5 - Grounds Person'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null || value == user.role) return;
                    onRoleChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => onRoleChanged(isAdmin ? 2 : 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isAdmin ? 'Demote' : 'Promote'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardData {
  const _AdminDashboardData({
    required this.users,
    required this.schools,
    required this.tasks,
  });

  final List<UserModel> users;
  final List<SchoolModel> schools;
  final List<TaskModel> tasks;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final dueText =
        task.dueAt == null
            ? 'No due date'
            : '${task.dueAt!.year}-${task.dueAt!.month.toString().padLeft(2, '0')}-${task.dueAt!.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: AppColors.longhornMaroon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  task.targetRole == 0
                      ? 'All roles'
                      : 'Role ${task.targetRole}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.longhornMaroon,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(task.description),
          const SizedBox(height: 10),
          Text('Due: $dueText', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 6),
          Text(
            'Status: ${task.status}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
