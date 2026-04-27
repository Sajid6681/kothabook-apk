import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'profile_screen.dart';

const String _kBaseUrl = 'https://app.kothabook.com/api';

class FriendRequestsScreen extends StatefulWidget {
  final VoidCallback? onRequestsRead;

  const FriendRequestsScreen({super.key, this.onRequestsRead});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _currentUserId = '';

  List<dynamic> _friendRequests  = [];
  List<dynamic> _suggestions     = [];
  List<dynamic> _friends         = [];

  bool _loadingRequests   = true;
  bool _loadingSuggestions = true;
  bool _loadingFriends    = true;

  // Track states locally for smooth UI
  final Map<String, String> _requestStates  = {}; // userId → 'accepted' | 'declined'
  final Map<String, bool>   _sentRequests   = {}; // userId → true (sent)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    await Future.wait([
      _fetchFriendRequests(),
      _fetchSuggestions(),
      _fetchFriends(),
    ]);
    widget.onRequestsRead?.call();
  }

  Future<void> _fetchFriendRequests() async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/friend-requests/$_currentUserId'));
      if (res.statusCode == 200 && mounted) {
        setState(() { _friendRequests = jsonDecode(res.body); _loadingRequests = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingRequests = false); }
  }

  Future<void> _fetchSuggestions() async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/friend-suggestions/$_currentUserId'));
      if (res.statusCode == 200 && mounted) {
        setState(() { _suggestions = jsonDecode(res.body); _loadingSuggestions = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingSuggestions = false); }
  }

  Future<void> _fetchFriends() async {
    try {
      final res = await http.get(Uri.parse('$_kBaseUrl/friends/$_currentUserId'));
      if (res.statusCode == 200 && mounted) {
        setState(() { _friends = jsonDecode(res.body); _loadingFriends = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingFriends = false); }
  }

  Future<void> _acceptRequest(String fromUserId) async {
    setState(() => _requestStates[fromUserId] = 'accepted');
    try {
      await http.post(Uri.parse('$_kBaseUrl/accept-friend-request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'currentUserId': _currentUserId, 'fromUserId': fromUserId}));
      await _fetchFriends();
    } catch (_) {}
  }

  Future<void> _declineRequest(String fromUserId) async {
    setState(() => _requestStates[fromUserId] = 'declined');
    try {
      await http.post(Uri.parse('$_kBaseUrl/decline-friend-request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'currentUserId': _currentUserId, 'fromUserId': fromUserId}));
    } catch (_) {}
  }

  Future<void> _sendRequest(String toUserId) async {
    setState(() => _sentRequests[toUserId] = true);
    try {
      await http.post(Uri.parse('$_kBaseUrl/send-friend-request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fromUserId': _currentUserId, 'toUserId': toUserId}));
    } catch (_) {}
  }

  Future<void> _unfriend(String targetUserId) async {
    // ✅ Confirmation popup (already shown in UI before calling this)
    try {
      await http.post(Uri.parse('$_kBaseUrl/unfriend'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'currentUserId': _currentUserId, 'targetUserId': targetUserId}));
      await _fetchFriends();
    } catch (_) {}
  }

  String _defaultPic(dynamic user) {
    return user['profilePic']?.toString().isNotEmpty == true
        ? user['profilePic']
        : (user['gender']?.toString().toLowerCase() == 'female'
            ? 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_female.png'
            : 'https://kothabook.com/kothabook_api/uploads/default_profile/blank_profile_male.png');
  }

  String _fullName(dynamic user) =>
      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();

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
                    child: Text('Friends', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                  ),
                  // Request count badge
                  if (_friendRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFF6D00), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${_friendRequests.where((r) => _requestStates[r['_id']] == null).length} new',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ]),
                const SizedBox(height: 8),

                // ── Tabs ──
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
                        const Icon(Icons.people_outline_rounded, size: 16),
                        const SizedBox(width: 4),
                        const Text('Requests'),
                        if (_friendRequests.where((r) => _requestStates[r['_id']] == null).length > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFFFF6D00), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${_friendRequests.where((r) => _requestStates[r['_id']] == null).length}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ]),
                    ),
                    const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_add_outlined, size: 16), SizedBox(width: 4), Text('Suggested')])),
                    const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.group_rounded, size: 16), SizedBox(width: 4), Text('Friends')])),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildSuggestionsTab(),
                _buildFriendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FRIEND REQUESTS TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildRequestsTab() {
    if (_loadingRequests) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));

    final pending = _friendRequests.where((r) => _requestStates[r['_id']] == null).toList();
    final responded = _friendRequests.where((r) => _requestStates[r['_id']] != null).toList();

    if (_friendRequests.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No friend requests', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('When someone sends you a friend request,\nyou\'ll see it here', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pending.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('${pending.length} Friend Request${pending.length > 1 ? 's' : ''}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)))),
          ...pending.map((req) => _buildRequestCard(req)),
        ],
        if (responded.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Responded', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey))),
          ...responded.map((req) => _buildRequestCard(req, isResponded: true)),
        ],
      ],
    );
  }

  Widget _buildRequestCard(dynamic req, {bool isResponded = false}) {
    final String userId  = req['_id'] ?? '';
    final String pic     = _defaultPic(req);
    final String name    = _fullName(req);
    final int mutual     = req['mutualFriendsCount'] ?? 0;
    final String? state  = _requestStates[userId];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: userId))),
          child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(pic)),
        ),
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: userId))),
          child: Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mutual > 0)
              Text('$mutual mutual friend${mutual > 1 ? 's' : ''}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            if (state != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state == 'accepted' ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state == 'accepted' ? '✓ Friend Added' : 'Request Declined',
                    style: GoogleFonts.poppins(fontSize: 12, color: state == 'accepted' ? Colors.green : Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6D00),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Confirm', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRequest(userId),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Delete', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SUGGESTED FRIENDS TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildSuggestionsTab() {
    if (_loadingSuggestions) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No suggestions right now', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('People You May Know', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)))),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: _suggestions.length,
          itemBuilder: (_, i) {
            final s = _suggestions[i];
            final String userId = s['_id'] ?? '';
            final String pic    = _defaultPic(s);
            final String name   = _fullName(s);
            final int mutual    = s['mutualFriendsCount'] ?? 0;
            final bool sent     = _sentRequests[userId] == true;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: userId))),
                    child: CircleAvatar(radius: 38, backgroundImage: NetworkImage(pic)),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  if (mutual > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('$mutual mutual', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: sent
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                            child: Text('Request Sent', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _sendRequest(userId),
                            icon: const Icon(Icons.person_add_rounded, size: 14),
                            label: Text('Add Friend', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6D00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // FRIENDS TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildFriendsTab() {
    if (_loadingFriends) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)));

    if (_friends.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No friends yet', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Add friends to see them here', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('${_friends.length} Friend${_friends.length > 1 ? 's' : ''}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)))),
        ..._friends.map((f) {
          final String userId = f['_id'] ?? '';
          final String pic    = _defaultPic(f);
          final String name   = _fullName(f);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: userId))),
                child: CircleAvatar(radius: 26, backgroundImage: NetworkImage(pic)),
              ),
              title: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: userId))),
                child: Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              subtitle: Text('Friend', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF6B6B6B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'unfriend') {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Unfriend $name?'),
                      content: Text('Are you sure you want to remove $name from your friends?', style: GoogleFonts.poppins(fontSize: 13)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () { Navigator.pop(context); _unfriend(userId); },
                          child: const Text('Unfriend', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ));
                  } else if (val == 'profile') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(isOwnProfile: false, profileUserId: userId)));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'profile', child: Row(children: [const Icon(Icons.person_outline_rounded, size: 18), const SizedBox(width: 10), Text('View Profile', style: GoogleFonts.poppins(fontSize: 13))])),
                  PopupMenuItem(value: 'unfriend', child: Row(children: [const Icon(Icons.person_remove_outlined, size: 18, color: Colors.red), const SizedBox(width: 10), Text('Unfriend', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red))])),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
