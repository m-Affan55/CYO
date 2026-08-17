import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/api_service.dart';

class SearchFriendsScreen extends ConsumerStatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  ConsumerState<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends ConsumerState<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<dynamic> _results = [];
  
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await ref.read(authServiceProvider).getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/friends/search?q=${Uri.encodeComponent(query.trim())}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error searching friends: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendFriendRequest(String username, int index) async {
    try {
      // Optimistically update UI
      setState(() {
        _results[index]['friendship_status'] = 'PENDING_SENT';
      });

      final token = await ref.read(authServiceProvider).getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/friends/request/$username'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode != 200 && mounted) {
        // Revert on failure
        setState(() {
          _results[index]['friendship_status'] = 'NONE';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _cancelRequest(String username, int index) async {
    try {
      // Optimistically update UI
      setState(() {
        _results[index]['friendship_status'] = 'NONE';
      });

      final token = await ref.read(authServiceProvider).getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/friends/cancel/$username'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode != 200 && mounted) {
        // Revert on failure
        setState(() {
          _results[index]['friendship_status'] = 'PENDING_SENT';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel request')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildActionButton(Map<String, dynamic> user, int index) {
    final status = user['friendship_status'];
    
    if (status == 'SELF') {
      return const SizedBox.shrink();
    }
    
    if (status == 'FRIENDS') {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2A2A2A)),
          backgroundColor: Colors.transparent,
        ),
        child: const Text('Friends', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    
    if (status == 'PENDING_RECEIVED') {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.successGreen),
          backgroundColor: Colors.transparent,
        ),
        child: const Text('Review', style: TextStyle(color: AppTheme.successGreen)),
      );
    }
    
    if (status == 'PENDING_SENT') {
      return OutlinedButton(
        onPressed: () => _cancelRequest(user['username'], index),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2A2A2A)),
          backgroundColor: AppTheme.surfaceCharcoal,
        ),
        child: const Text('Requested', style: TextStyle(color: AppTheme.textPrimary)),
      );
    }
    
    // Default NONE
    return ElevatedButton(
      onPressed: () => _sendFriendRequest(user['username'], index),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryRed,
      ),
      child: const Text('Add'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search friends...',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF2A2A2A),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
            : _results.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Text(
                      'No users found for "${_searchController.text}"',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'Type a username to search.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final colorStr = user['color'] ?? '#FF3B30';
                          final color = _hexToColor(colorStr);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color,
                              child: Text(
                                user['username'].substring(0, 2).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user['username'], style: const TextStyle(color: AppTheme.textPrimary)),
                            subtitle: user['status'] != null
                                ? Text(user['status'], style: const TextStyle(color: AppTheme.textMuted))
                                : null,
                            trailing: _buildActionButton(user, index),
                          );
                        },
                      ),
      ),
    );
  }
}
