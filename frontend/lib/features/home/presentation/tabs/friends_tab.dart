import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/api_service.dart';

class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key});

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab> {
  List<dynamic> _friends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);
    try {
      final token = await ref.read(authServiceProvider).getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/friends/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _friends = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching friends: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FRIENDS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed, letterSpacing: 2),
              ),
              IconButton(
                icon: const Icon(Icons.person_add, color: AppTheme.textPrimary),
                onPressed: () => context.push('/search-friends'),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          else if (_friends.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No friends yet. Add some!', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryRed,
                      child: Text(friend['username'].substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(friend['username'], style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(friend['status'] ?? 'Online', style: const TextStyle(color: AppTheme.textMuted)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
