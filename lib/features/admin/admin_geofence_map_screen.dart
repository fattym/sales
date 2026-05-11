import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminGeofenceMapScreen extends StatefulWidget {
  const AdminGeofenceMapScreen({super.key});

  @override
  State<AdminGeofenceMapScreen> createState() => _AdminGeofenceMapScreenState();
}

class _AdminGeofenceMapScreenState extends State<AdminGeofenceMapScreen> {
  final _supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  int _selectedRoleFilter = 4;
  List<Map<String, dynamic>> _existingGeofences = [];
  String? _selectedUserId;
  bool _isLoadingUsers = true;

  // Geofence states
  LatLng? _selectedLocation;
  double _geofenceRadiusMeters = 500.0;

  // Default start location (e.g., center of a relevant city/country)
  static const LatLng _initialCenter = LatLng(
    -1.2921,
    36.8219,
  ); // Nairobi, Kenya

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch all non-admin users to populate the dropdown
      final usersResponse = await _supabase
          .from('users')
          .select('id, full_name, email, role')
          .neq('role', 1);

      // Fetch existing geofences to display on the map
      final geofencesResponse = await _supabase.from('geofences').select('*');

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(usersResponse);
          _filterUsers();
          _existingGeofences = List<Map<String, dynamic>>.from(
            geofencesResponse,
          );
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _filterUsers() {
    _filteredUsers =
        _users.where((u) => u['role'] == _selectedRoleFilter).toList();
    if (!_filteredUsers.any((u) => u['id'].toString() == _selectedUserId)) {
      _selectedUserId = null;
    }
  }

  List<CircleMarker> _buildExistingGeofenceCircles() {
    List<CircleMarker> markers = [];
    for (var geo in _existingGeofences) {
      final coords = geo['coordinates'];
      if (coords != null && coords is List && coords.isNotEmpty) {
        for (var point in coords) {
          final lat = (point['lat'] as num?)?.toDouble();
          final lng = (point['lng'] as num?)?.toDouble();
          final radius = (point['radius'] as num?)?.toDouble();
          if (lat != null && lng != null && radius != null) {
            markers.add(
              CircleMarker(
                point: LatLng(lat, lng),
                radius: radius,
                useRadiusInMeter: true,
                color: Colors.grey.withOpacity(0.3),
                borderColor: Colors.grey,
                borderStrokeWidth: 2,
              ),
            );
          }
        }
      }
    }
    return markers;
  }

  Future<void> _centerOnCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        14.0, // Zoom in closer to the admin's location
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _onMapTapped(TapPosition _, LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  Future<void> _assignGeofenceTask() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to set a geofence center.'),
        ),
      );
      return;
    }

    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user to assign this area to.'),
        ),
      );
      return;
    }

    try {
      await _supabase.from('geofences').insert({
        'name': 'Cover Geofenced Area',
        'description': 'Please cover the assigned geographic area.',
        'assigned_to': _selectedUserId,
        'coordinates': [
          {
            'lat': _selectedLocation!.latitude,
            'lng': _selectedLocation!.longitude,
            'radius': _geofenceRadiusMeters,
          },
        ],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geofence assigned successfully!')),
        );
        setState(() {
          _selectedLocation = null;
          _selectedUserId = null;
        });
        _fetchData(); // Refresh map with the new geofence
      }
    } catch (e) {
      debugPrint('Error assigning geofence: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final mapContent = Stack(
      children: [
        // Full screen map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 12.0,
            onMapReady: _centerOnCurrentLocation,
            onTap: _onMapTapped,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.longhorn.dehus',
            ),
            CircleLayer(
              circles: [
                ..._buildExistingGeofenceCircles(),
                if (_selectedLocation != null)
                  CircleMarker(
                    point: _selectedLocation!,
                    radius: _geofenceRadiusMeters,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
              ],
            ),
            if (_selectedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Custom location button since FlutterMap doesn't include one by default
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _centerOnCurrentLocation,
            child: const Icon(Icons.my_location, color: Colors.black87),
          ),
        ),
      ],
    );

    final controlPanel = Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1. Tap the map to select a location',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('2. Adjust Radius: ${_geofenceRadiusMeters.toInt()}m'),
          Slider(
            value: _geofenceRadiusMeters,
            min: 100,
            max: 5000,
            divisions: 49,
            label: '${_geofenceRadiusMeters.toInt()}m',
            onChanged: (value) {
              setState(() {
                _geofenceRadiusMeters = value;
              });
            },
          ),
          const SizedBox(height: 8),
          const Text(
            '3. Select User to Tag',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Role:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedRoleFilter,
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('Manager (Role 2)')),
                    DropdownMenuItem(value: 3, child: Text('BAS (Role 3)')),
                    DropdownMenuItem(value: 4, child: Text('Agent (Role 4)')),
                    DropdownMenuItem(value: 5, child: Text('Grounds (Role 5)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRoleFilter = val;
                        _filterUsers();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                hint: const Text('Choose a user...'),
                value: _selectedUserId,
                items:
                    _filteredUsers.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'].toString(),
                        child: Text(
                          user['full_name'] ?? user['email'] ?? 'Unknown User',
                        ),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => _selectedUserId = val),
              ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _assignGeofenceTask,
            child: const Text('Tag User & Assign Geofence'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Geofence')),
      body:
          isDesktop
              ? Row(
                children: [
                  Expanded(child: mapContent),
                  SizedBox(
                    width: 350,
                    child: Center(
                      child: SingleChildScrollView(child: controlPanel),
                    ),
                  ),
                ],
              )
              : Stack(
                children: [
                  mapContent,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: SingleChildScrollView(child: controlPanel),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
