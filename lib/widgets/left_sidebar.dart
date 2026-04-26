import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_dialog.dart';
import '../login_screen.dart';

class LeftSidebar extends StatelessWidget {
  final VoidCallback onClose;

  const LeftSidebar({super.key, required this.onClose});

  void _handleLogout(BuildContext context) {
    CustomDialog.show(
      context: context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of KothaBook?',
      confirmText: 'Log Out',
      isDestructive: true,
      onConfirm: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }

  void _handleDarkMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dark Mode will be available in the next update! 🌙'),
        backgroundColor: Color(0xFF1A1A1A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu',
                  style: GoogleFonts.righteous(
                    fontSize: 22,
                    color: const Color(0xFFFF6D00),
                    letterSpacing: 1.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              // 🚀 FIXED: Bottom Nav Bar এর কারণে যেন ঢাকা না পড়ে তাই bottom 120 প্যাডিং দেওয়া হলো
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 120, 
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            NetworkImage('https://i.pravatar.cc/150?img=11'),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sajid Baby',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'View your profile',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFFFF6D00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Features',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildShortcutCard(Icons.feed_outlined, 'Newsfeed'),
                    _buildShortcutCard(
                        Icons.bookmark_border_rounded, 'Saved'),
                    _buildShortcutCard(Icons.schedule_rounded, 'Scheduled'),
                    _buildShortcutCard(Icons.history_rounded, 'Memories'),
                    _buildShortcutCard(
                        Icons.people_outline_rounded, 'People'),
                    _buildShortcutCard(Icons.groups_outlined, 'Groups'),
                    _buildShortcutCard(Icons.flag_outlined, 'Pages'),
                    _buildShortcutCard(
                        Icons.slow_motion_video_rounded, 'Reels'),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildSidebarListItem(
                        Icons.settings_outlined,
                        'Settings & Privacy',
                        () {},
                      ),
                      _buildSidebarListItem(
                        Icons.help_outline_rounded,
                        'Help & Support',
                        () {},
                      ),
                      // 🚀 Added Actions here (With your exact previous code)
                      _buildSidebarListItem(
                        Icons.dark_mode_outlined,
                        'Dark Mode',
                        () => _handleDarkMode(context),
                      ),
                      _buildSidebarListItem(
                        Icons.logout_rounded,
                        'Log Out',
                        () => _handleLogout(context),
                        color: Colors.red,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildShortcutCard(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFF6D00), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarListItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = const Color(0xFF1A1A1A),
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.red ? Colors.red : const Color(0xFF65676B),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}