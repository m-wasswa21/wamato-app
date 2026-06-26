import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/notification_repository.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationRepository();
  List<Map<String, dynamic>> _notifs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getNotifications(size: 50);
      if (mounted) setState(() { _notifs = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _unreadCount => _notifs.where((n) => n['is_read'] == false).length;

  Future<void> _markRead(int index) async {
    final n = _notifs[index];
    if (n['is_read'] == true) return;
    try {
      await _repo.markRead(n['id'].toString());
      if (mounted) setState(() => _notifs[index] = {...n, 'is_read': true});
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _repo.markAllRead();
      if (mounted) {
        setState(() {
          _notifs = _notifs.map((n) => {...n, 'is_read': true}).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications',
                style: GoogleFonts.urbanist(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            if (!_isLoading && _unreadCount > 0)
              Text('$_unreadCount unread',
                  style: GoogleFonts.urbanist(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          if (!_isLoading && _unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: GoogleFonts.urbanist(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? _buildShimmer()
            : _notifs.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NotifTile(
                      notif: _notifs[i],
                      onTap: () => _markRead(i),
                      onDismiss: () =>
                          setState(() => _notifs.removeAt(i)),
                    ),
                  ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppColors.accent, size: 64),
          const SizedBox(height: 16),
          Text('No Notifications',
              style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          Text("You're all caught up!",
              style: GoogleFonts.urbanist(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifTile(
      {required this.notif, required this.onTap, required this.onDismiss});

  static (IconData, Color) _iconFor(String? type) {
    switch (type) {
      case 'message':
        return (Icons.message_rounded, AppColors.secondary);
      case 'price_drop':
        return (Icons.price_change_rounded, AppColors.success);
      case 'verified':
        return (Icons.verified_rounded, AppColors.success);
      case 'views':
        return (Icons.visibility_rounded, AppColors.warning);
      case 'featured':
        return (Icons.star_rounded, AppColors.warning);
      case 'enquiry':
        return (Icons.people_rounded, AppColors.secondary);
      default:
        return (Icons.home_rounded, AppColors.primary);
    }
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notif['is_read'] == true;
    final (icon, color) = _iconFor(notif['type'] as String?);
    final title = notif['title'] as String? ?? 'Notification';
    final body = notif['body'] as String? ?? notif['message'] as String? ?? '';
    final time = _timeAgo(notif['created_at'] as String?);

    return Dismissible(
      key: ValueKey(notif['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 24),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? AppColors.white : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isRead
                    ? AppColors.border.withOpacity(0.4)
                    : color.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                  color: AppColors.dark)),
                        ),
                        if (!isRead)
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(body,
                        style: GoogleFonts.urbanist(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(time,
                        style: GoogleFonts.urbanist(
                            fontSize: 11,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
