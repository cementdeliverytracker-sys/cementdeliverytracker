import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/theme/theme_notifier.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_employee_service.dart';
import 'package:cementdeliverytracker/shared/widgets/change_password_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load user data when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authNotifier = context.read<AuthNotifier>();
      final currentUser = authNotifier.user;
      if (currentUser != null) {
        context.read<DashboardProvider>().loadUserData(currentUser.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final userData = dashboardProvider.userData;
        final role = userData?.userType ?? 'admin';

        if (userData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  dashboardProvider.errorMessage ?? 'Loading profile...',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        // Only show tabs for admin users
        if (role == AppConstants.userTypeAdmin) {
          return Container(
            color: const Color(0xFF2C2C2C),
            child: Column(
              children: [
                Container(
                  color: const Color(0xFF1E1E1E),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFFF6F00),
                    labelColor: const Color(0xFFFF6F00),
                    unselectedLabelColor: Colors.white60,
                    tabs: const [
                      Tab(text: 'General'),
                      Tab(text: 'Location'),
                      Tab(text: 'Employee Management'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralSettings(userData, role),
                      _LocationTab(userId: userData.userId),
                      _EmployeeManagementTab(userId: userData.userId),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // For non-admin users, show general settings only
        return Container(
          color: const Color(0xFF2C2C2C),
          child: _buildGeneralSettings(userData, role),
        );
      },
    );
  }

  Widget _buildGeneralSettings(userData, String role) {
    return ListView(
      children: [
        // Profile Info Section
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person, color: Colors.white),
          title: Text(
            'Username: ${userData.username}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.email, color: Colors.white),
          title: Text(
            'Email: ${userData.email}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        if (role == AppConstants.userTypeAdmin) ...[
          ListTile(
            leading: const Icon(Icons.badge, color: Colors.white),
            title: Text(
              'Admin ID: ${userData.adminId ?? 'Not assigned'}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Share this ID when needed. It cannot be changed.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          _EmployeeCodeCard(userId: userData.userId),
        ],
        const Divider(color: Colors.white24),

        // Theme Toggle
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, _) {
            return SwitchListTile(
              title: const Text(
                'Dark Theme',
                style: TextStyle(color: Colors.white),
              ),
              value: themeNotifier.isDarkTheme,
              onChanged: (value) {
                themeNotifier.setTheme(value);
              },
              activeThumbColor: const Color(0xFFFF6F00),
            );
          },
        ),
        const Divider(color: Colors.white24),

        // Account Settings
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock, color: Colors.white),
          title: const Text(
            'Change Password',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const ChangePasswordDialog(),
            );
          },
        ),

        // Role-based sections
        if (role == 'super_admin') ...[
          ListTile(
            leading: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
            ),
            title: const Text(
              'Manage Admins',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              // TODO: Navigate to manage admins screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Manage Admins tapped')),
              );
            },
          ),
        ],

        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          onTap: () async {
            await context.read<AuthNotifier>().logout();
          },
        ),
      ],
    );
  }
}

class _LocationTab extends StatefulWidget {
  final String userId;

  const _LocationTab({required this.userId});

  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  bool _saving = false;
  bool _locationSet = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCodeCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocationData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.enterprisesCollection)
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        final location = data?['location'] as Map<String, dynamic>?;
        final locationSet = data?['locationSet'] as bool? ?? false;

        setState(() {
          _locationSet = locationSet;
          if (location != null) {
            _addressCtrl.text = location['address'] ?? '';
            _cityCtrl.text = location['city'] ?? '';
            _stateCtrl.text = location['state'] ?? '';
            _zipCodeCtrl.text = location['zipCode'] ?? '';
            _countryCtrl.text = location['country'] ?? '';
            _latitude = (location['latitude'] as num?)?.toDouble();
            _longitude = (location['longitude'] as num?)?.toDouble();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading location: $e')));
      }
    }
  }

  Future<void> _pickLocationFromMap() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      // Open map picker dialog
      final LatLng? pickedLocation = await showDialog<LatLng>(
        context: context,
        builder: (context) => _MapPickerDialog(
          initialPosition: LatLng(position.latitude, position.longitude),
        ),
      );

      if (pickedLocation != null) {
        // Get address from coordinates
        await _getAddressFromCoordinates(
          pickedLocation.latitude,
          pickedLocation.longitude,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking location: $e')));
      }
    }
  }

  Future<void> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          _latitude = latitude;
          _longitude = longitude;
          _addressCtrl.text =
              '${place.street ?? ''}, ${place.subLocality ?? ''}';
          _cityCtrl.text = place.locality ?? '';
          _stateCtrl.text = place.administrativeArea ?? '';
          _zipCodeCtrl.text = place.postalCode ?? '';
          _countryCtrl.text = place.country ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting address: $e')));
      }
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select location from map'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.enterprisesCollection)
          .doc(widget.userId)
          .set({
            'location': {
              'address': _addressCtrl.text.trim(),
              'city': _cityCtrl.text.trim(),
              'state': _stateCtrl.text.trim(),
              'zipCode': _zipCodeCtrl.text.trim(),
              'country': _countryCtrl.text.trim(),
              'latitude': _latitude!,
              'longitude': _longitude!,
            },
            'locationSet': true,
            'locationSetAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _locationSet = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save location: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enterprise Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_locationSet)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Location already set. Cannot be changed.',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Set your business location for better service management',
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _addressCtrl,
              enabled: !_locationSet,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'e.g., 123 Main Street',
                prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF6F00)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    enabled: !_locationSet,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'e.g., Mumbai',
                      prefixIcon: Icon(
                        Icons.location_city,
                        color: Color(0xFFFF6F00),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'City is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateCtrl,
                    enabled: !_locationSet,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'State',
                      hintText: 'e.g., Maharashtra',
                      prefixIcon: Icon(Icons.map, color: Color(0xFFFF6F00)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'State is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeCtrl,
                    enabled: !_locationSet,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ZIP Code',
                      hintText: 'e.g., 400001',
                      prefixIcon: Icon(
                        Icons.markunread_mailbox,
                        color: Color(0xFFFF6F00),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'ZIP code is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _countryCtrl,
                    enabled: !_locationSet,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      hintText: 'e.g., India',
                      prefixIcon: Icon(Icons.public, color: Color(0xFFFF6F00)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Country is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _locationSet ? null : _pickLocationFromMap,
              icon: const Icon(Icons.map, color: Color(0xFFFF6F00)),
              label: const Text(
                'Pick Location from Map',
                style: TextStyle(color: Color(0xFFFF6F00)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6F00)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_saving || _locationSet) ? null : _saveLocation,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _locationSet
                      ? 'Location Already Set'
                      : (_saving ? 'Saving...' : 'Save Location'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeManagementTab extends StatefulWidget {
  final String userId;

  const _EmployeeManagementTab({required this.userId});

  @override
  State<_EmployeeManagementTab> createState() => _EmployeeManagementTabState();
}

class _EmployeeManagementTabState extends State<_EmployeeManagementTab> {
  final AdminEmployeeService _employeeService = AdminEmployeeService();
  bool _isLoading = false;

  Future<void> _logoffAllEmployees() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Logout All Employees?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will set all employees\' status to logged out. This action cannot be undone immediately.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await _employeeService.logoffAllEmployees(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All employees have been logged out'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout employees: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Employee Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logout All Employees',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set all employees\' status to logged out. Useful for end-of-day operations or system resets.',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isLoading ? null : _logoffAllEmployees,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.logout),
                  label: Text(
                    _isLoading ? 'Processing...' : 'Logout All Employees',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmployeeCodeCard extends StatelessWidget {
  final String userId;

  const _EmployeeCodeCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.enterprisesCollection)
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: Icon(Icons.vpn_key, color: Colors.white),
            title: Text(
              'Loading employee code...',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final data = snapshot.data?.data();
        final adminCode = (data?['adminCode'] ?? '') as String;

        if (adminCode.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.vpn_key, size: 20, color: Color(0xFFFF6F00)),
                      SizedBox(width: 8),
                      Text(
                        'Employee Join Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share this code with employees to join your company',
                    style: TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          adminCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Color(0xFFFF6F00),
                            letterSpacing: 3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: Color(0xFFFF6F00),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: adminCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapPickerDialog extends StatefulWidget {
  final LatLng initialPosition;

  const _MapPickerDialog({required this.initialPosition});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late LatLng _selectedPosition;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _markers.add(
      Marker(
        markerId: const MarkerId('selected'),
        position: _selectedPosition,
        draggable: true,
        onDragEnd: (newPosition) {
          setState(() {
            _selectedPosition = newPosition;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: 500,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pick Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialPosition,
                    zoom: 15,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (position) {
                    setState(() {
                      _selectedPosition = position;
                      _markers.clear();
                      _markers.add(
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: position,
                          draggable: true,
                          onDragEnd: (newPosition) {
                            setState(() {
                              _selectedPosition = newPosition;
                            });
                          },
                        ),
                      );
                    });
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, _selectedPosition),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F00),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
