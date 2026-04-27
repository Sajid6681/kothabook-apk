import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../friend_requests_screen.dart';
import '../notifications_screen.dart';

const String _kBaseUrl = 'https://app.kothabook.com/api';

class TopNavBar extends StatefulWidget {
  final VoidCallback onMenuTap;
  const TopNavBar({super.key, required this.onMenuTap});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  int _friendRequestCount = 0;
  int _notificationCount  = 0;
  String _currentUserId   = '';

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId') ?? '';
    if (_currentUserId.isEmpty) return;
    await Future.wait([_fetchFriendRequestCount(), _fetchNotificationCount()]);
  }

  Future<void> _fetchFriendRequestCount() async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/friend-requests/$_currentUserId'));
      if (res.statusCode == 200 && mounted) {
        final list = jsonDecode(res.body) as List;
        setState(() => _friendRequestCount = list.length);
      }
    } catch (_) {}
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/notifications/$_currentUserId?unreadOnly=true'));
      if (res.statusCode == 200 && mounted) {
        final list = jsonDecode(res.body) as List;
        setState(() => _notificationCount = list.length);
      }
    } catch (_) {}
  }

  Widget _buildBadgeIcon({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 30, color: const Color(0xFF1A1A1A)),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: Hamburger Menu
          GestureDetector(
            onTap: widget.onMenuTap,
            child: const Icon(Icons.menu_rounded, size: 30, color: Color(0xFF1A1A1A)),
          ),

          // ── Center: Logo
          Text(
            'KOTHABOOK',
            style: GoogleFonts.righteous(
              fontSize: 22,
              color: const Color(0xFFFF6D00),
              letterSpacing: 1.5,
            ),
          ),

          // ── Right: Search + Friend Request + Notification
          Row(
            children: [
              // Search
              GestureDetector(
                onTap: () {
                  // Search screen navigate করবে
                },
                child: const Icon(Icons.search_rounded, size: 30, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(width: 16),

              // Friend Request
              _buildBadgeIcon(
                icon: Icons.people_outline_rounded,
                count: _friendRequestCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FriendRequestsScreen(
                        onRequestsRead: () => setState(() => _friendRequestCount = 0),
                      ),
                    ),
                  ).then((_) => _fetchFriendRequestCount());
                },
              ),
              const SizedBox(width: 16),

              // Notification
              _buildBadgeIcon(
                icon: Icons.notifications_none_rounded,
                count: _notificationCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(
                        onNotificationsRead: () => setState(() => _notificationCount = 0),
                      ),
                    ),
                  ).then((_) => _fetchNotificationCount());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
