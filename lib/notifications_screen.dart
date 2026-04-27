import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'profile_screen.dart';

const String _kBaseUrl = 'https://app.kothabook.com/api';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onNotificationsRead;

  const NotificationsScreen({super.key, this.onNotificationsRead});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _currentUserId = '';
  List<dynamic> _allNotifications  = [];
  List<dynamic> _unreadNotifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId') ?? '';
    await _fetchNotifications();
    widget.onNotificationsRead?.call();
    // সব notification mark as read করো
    _markAllRead();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/notifications/$_currentUserId'));
      if (res.statusCode == 200 && mounted) {
        final all = jsonDecode(res.body) as List;
        setState(() {
          _allNotifications    = all;
          _unreadNotifications = all.where((n) => n['isRead'] == false).toList();
          _loading = false;
        });
      }
    } catch (_) {
      // Backend তে notification route না থাকলে mock data দেখাবে
      _useMockNotifications();
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useMockNotifications() {
    // Backend এ notification model না থাকলে posts থেকে reactions / comments টেনে notification বানাই
    _fetchNotificationsFromPosts();
  }

  Future<void> _fetchNotificationsFromPosts() async {
    try {
      // নিজের posts এর reactions এবং comments notification হিসেবে দেখাবে
      final postsRes = await http.get(Uri.parse('$_kBaseUrl/user-posts/$_currentUserId'));
      // friend requests notification
      final frRes = await http.get(Uri.parse('$_kBaseUrl/friend-requests/$_currentUserId'));

      final List<dynamic> notifications = [];

      if (postsRes.statusCode == 200) {
        final posts = jsonDecode(postsRes.body) as List;
        for (final post in posts) {
          final postId = post['_id'];
          final postText = (post['textContent'] as String?)?.isNotEmpty == true
              ? post['textContent']
              : 'your post';

          // Reactions
          final likes = (post['likes'] as List?) ?? [];
          for (final like in likes) {
            if (like['userId'] != _currentUserId) {
              notifications.add({
                '_id': '${postId}_${like['userId']}_reaction',
                'type': 'reaction',
                'actorId': like['userId'],
                'actorName': 'Someone',
                'reactionType': like['reactionType'] ?? 'Like',
                'postId': postId,
                'postText': postText,
                'isRead': false,
                'createdAt': post['createdAt'],
                'postImageUrl': post['postImageUrl'] ?? '',
              });
            }
          }

          // Comments
          final comments = (post['comments'] as List?) ?? [];
          for (final comment in comments) {
            if (comment['userId'] != _currentUserId) {
              notifications.add({
                '_id': '${comment['_id']}_comment',
                'type': 'comment',
                'actorId': comment['userId'],
                'actorName': comment['userName'] ?? 'Someone',
                'actorPic': comment['userPic'] ?? '',
                'commentText': comment['commentText'] ?? '',
                'postId': postId,
                'postText': postText,
                'isRead': false,
                'createdAt': comment['time'],
                'postImageUrl': post['postImageUrl'] ?? '',
              });
            }
          }
        }
      }

      // Friend Requests
      if (frRes.statusCode == 200) {
        final requests = jsonDecode(frRes.body) as List;
        for (final req in requests) {
          notifications.add({
            '_id': '${req['_id']}_friend_request',
            'type': 'friend_request',
            'actorId': req['_id'],
            'actorName': '${req['firstName'] ?? ''} ${req['lastName'] ?? ''}',
            'actorPic': req['profilePic'] ?? '',
            'gender': req['gender'] ?? 'male',
            'mutualFriendsCount': req['mutualFriendsCount'] ?? 0,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      // Sort by date descending
      notifications.sort((a, b) {
        try {
          final da = DateTime.parse(a['createdAt'].toString());
          final db = DateTime.parse(b['createdAt'].toString());
          return db.compareTo(da);
        } catch (_) { return 0; }
      });

      if (mounted) {
        setState(() {
          _allNotifications    = notifications;
          _unreadNotifications = notifications.where((n) => n['isRead'] == false).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await http.post(
        Uri.parse('$_kBaseUrl/notifications/$_currentUserId/mark-read'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }

  Future<void> _acceptFriendRequest(String fromUserId) async {
    try {
      await http.post(Uri.parse('$_kBaseUrl/accept-friend-request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'currentUserId': _currentUserId, 'fromUserId': fromUserId}));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request accepted! 🎉'), backgroundColor: Colors.green));
        _fetchNotifications();
      }
    } catch (_) {}
  }

  Future<void> _declineFriendRequest(String fromUserId) async {
    try {
      await http.post(Uri.parse('$_kBaseUrl/decline-friend-request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'currentUserId': _currentUserId, 'fromUserId': fromUserId}));
      if (mounted) _fetchNotifications();
    } catch (_) {}
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Just now';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) { return 'Just now'; }
  }

  String _defaultPic(dynamic notif) {
    if (notif['actorPic']?.toString().isNotEmpty == true) return notif['actorPic'];
    return notif['gender']?.toString().toLowerCase() == 'female'
        ? 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_female.png'
        : 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_male.png';
  }

  // Emoji for reaction type
  String _reactionEmoji(String type) {
    switch (type) {
      case 'Love':  return '❤️';
      case 'Haha':  return '😂';
      case 'Wow':   return '😮';
      case 'Sad':   return '😢';
      case 'Angry': return '😡';
      default:      return '👍';
    }
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'reaction':        return const Color(0xFFFF6D00);
      case 'comment':         return Colors.blue;
      case 'friend_request':  return Colors.green;
      case 'friend_accepted': return Colors.teal;
      case 'follow':          return Colors.purple;
      default:                return Colors.grey;
    }
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'reaction':        return Icons.favorite_rounded;
      case 'comment':         return Icons.chat_bubble_rounded;
      case 'friend_request':  return Icons.person_add_rounded;
      case 'friend_accepted': return Icons.people_rounded;
      case 'follow':          return Icons.person_add_alt_1_rounded;
      default:                return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 0,
              left: 4,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Color(0xFF1A1A1A)),
                  ),
                  Expanded(
                    child: Text('Notifications', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                  ),
                  if (_unreadNotifications.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFF6D00), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${_unreadNotifications.length} new',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ]),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFFF6D00),
                  unselectedLabelColor: const Color(0xFF6B6B6B),
                  indicatorColor: const Color(0xFFFF6D00),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.all_inbox_rounded, size: 16),
                        const SizedBox(width: 4),
                        const Text('All'),
                        if (_unreadNotifications.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFFFF6D00), borderRadius: BorderRadius.circular(10)),
                            child: Text('${_unreadNotifications.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                    ),
                    const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mark_email_unread_rounded, size: 16), SizedBox(width: 4), Text('Unread')])),
                  ],
                ),
              ],
            ),
          ),

          // ── Tabs ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotifList(_allNotifications),
                _buildNotifList(_unreadNotifications),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifList(List<dynamic> notifications) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));

    if (notifications.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No notifications', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('We\'ll notify you when something\nhappens on your posts', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
        ]),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFF6D00),
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (_, i) => _buildNotifItem(notifications[i]),
      ),
    );
  }

  Widget _buildNotifItem(dynamic notif) {
    final String type       = notif['type'] ?? '';
    final String actorId    = notif['actorId'] ?? '';
    final String actorName  = notif['actorName'] ?? 'Someone';
    final String actorPic   = _defaultPic(notif);
    final bool   isUnread   = notif['isRead'] == false;
    final String timeAgo    = _timeAgo(notif['createdAt']);
    final String postImg    = notif['postImageUrl'] ?? '';

    String notifText;
    switch (type) {
      case 'reaction':
        final emoji = _reactionEmoji(notif['reactionType'] ?? 'Like');
        notifText   = 'reacted $emoji to your post';
        break;
      case 'comment':
        notifText = 'commented on your post: "${notif['commentText'] ?? ''}"';
        break;
      case 'friend_request':
        notifText = 'sent you a friend request';
        break;
      case 'friend_accepted':
        notifText = 'accepted your friend request 🎉';
        break;
      case 'follow':
        notifText = 'started following you';
        break;
      default:
        notifText = 'interacted with you';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFFFF3EC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isUnread ? Border.all(color: const Color(0xFFFF6D00).withValues(alpha: 0.15), width: 1) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Actor Avatar with notification type badge
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: actorId))),
                      child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(actorPic)),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _notifColor(type),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(_notifIcon(type), size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // ── Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A1A)),
                          children: [
                            TextSpan(text: actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' '),
                            TextSpan(text: notifText),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(timeAgo, style: GoogleFonts.poppins(fontSize: 11, color: isUnread ? const Color(0xFFFF6D00) : Colors.grey, fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal)),
                    ],
                  ),
                ),

                // ── Post thumbnail (if any)
                if (postImg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(postImg, width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ),
              ],
            ),

            // ── Friend Request Actions
            if (type == 'friend_request') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptFriendRequest(actorId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Confirm', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineFriendRequest(actorId),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Delete', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                  ),
                ),
              ]),
              if ((notif['mutualFriendsCount'] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${notif['mutualFriendsCount']} mutual friend${(notif['mutualFriendsCount'] ?? 0) > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
