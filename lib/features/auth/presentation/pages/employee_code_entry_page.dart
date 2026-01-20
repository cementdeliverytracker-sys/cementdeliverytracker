import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/pending_approval_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EmployeeCodeEntryPage extends StatefulWidget {
  const EmployeeCodeEntryPage({super.key});

  @override
  State<EmployeeCodeEntryPage> createState() => _EmployeeCodeEntryPageState();
}

class _EmployeeCodeEntryPageState extends State<EmployeeCodeEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _adminCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthNotifier>().user?.id;
      if (userId == null) throw Exception('User not found');

      final adminCode = _adminCodeController.text.trim();

      // Verify admin code exists in enterprises collection
      final enterpriseQuery = await FirebaseFirestore.instance
          .collection(AppConstants.enterprisesCollection)
          .where('adminCode', isEqualTo: adminCode)
          .limit(1)
          .get();

      if (enterpriseQuery.docs.isEmpty) {
        throw Exception('Invalid admin code');
      }

      final enterpriseDoc = enterpriseQuery.docs.first;
      final adminOwnerId =
          enterpriseDoc.id; // Document ID is the admin's userId
      final enterpriseData = enterpriseDoc.data();

      // Debug: Log what we're storing
      print('DEBUG employee_code_entry: adminCode=$adminCode');
      print('DEBUG employee_code_entry: adminOwnerId=$adminOwnerId');
      print('DEBUG employee_code_entry: enterpriseData=$enterpriseData');

      // Update user document with pending employee status and adminId
      // Store the admin's actual user ID (UID) so requests can be queried by admin
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'userType': AppConstants.userTypePendingEmployee,
            'adminId': adminOwnerId,
            'employeeRequestData': {
              'requestedAt': FieldValue.serverTimestamp(),
              'status': 'pending',
              'adminCode': adminCode,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'Employee request submitted! Waiting for admin approval.',
        );
        // Send user straight to pending state and clear back stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PendingApprovalPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          e.toString().contains('Invalid')
              ? 'Invalid admin code. Please check and try again.'
              : 'Failed to join: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        title: const Text('Join as Employee'),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.vpn_key_outlined,
                size: 80,
                color: Color(0xFFFF6F00),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Admin Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ask your admin for the code to join your company',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Card(
                margin: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _adminCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Admin Code',
                            hintText: 'Enter the code provided by your admin',
                            prefixIcon: Icon(Icons.pin),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitCode(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter admin code';
                            }
                            if (value.trim().length < 6) {
                              return 'Admin code must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submitCode,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              _isLoading ? 'Verifying...' : 'Join Company',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Note: You will be added to your admin\'s team once the code is verified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
