import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/distributor_model.dart';
import '../../data/repositories/distributor_repository.dart';

/// Widget for selecting a distributor or adding a new one
class DistributorSelectorWidget extends StatefulWidget {
  final Function(Distributor) onSelected;
  final VoidCallback onAddNew;
  final String? adminId;

  const DistributorSelectorWidget({
    Key? key,
    required this.onSelected,
    required this.onAddNew,
    this.adminId,
  }) : super(key: key);

  @override
  State<DistributorSelectorWidget> createState() =>
      _DistributorSelectorWidgetState();
}

class _DistributorSelectorWidgetState extends State<DistributorSelectorWidget> {
  List<Distributor> _distributors = [];
  List<Distributor> _filteredDistributors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.adminId != null && widget.adminId!.isNotEmpty) {
      _loadDistributors();
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin ID not found. Please re-login.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadDistributors() async {
    try {
      final repository = context.read<DistributorRepository>();
      final distributors = await repository.getDistributors(
        adminId: widget.adminId,
      );
      setState(() {
        _distributors = distributors;
        _filteredDistributors = distributors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load distributors: $e')),
        );
      }
    }
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDistributors = _distributors;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredDistributors = _distributors.where((d) {
          return d.name.toLowerCase().contains(lowerQuery) ||
              d.contact.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          onChanged: _updateSearch,
          decoration: InputDecoration(
            hintText: 'Search distributors...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _updateSearch('');
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Distributors list
        if (_filteredDistributors.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.business_center,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? 'No distributors available'
                      : 'No distributors found',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 350,
            child: ListView.separated(
              itemCount: _filteredDistributors.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final distributor = _filteredDistributors[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  title: Text(
                    distributor.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        distributor.contact,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distributor.address,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        distributor.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    widget.onSelected(distributor);
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 12),

        // Add new distributor button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onAddNew,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Add New Distributor'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
