import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/services/message_repository.dart';
import '../../core/theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repo = MessageRepository();
  List<Map<String, dynamic>> _convs = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getConversations();
      if (mounted) {
        setState(() {
          _convs = data;
          _filtered = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _convs
          : _convs.where((c) {
              final name = _otherName(c).toLowerCase();
              return name.contains(q);
            }).toList();
    });
  }

  String _otherName(Map<String, dynamic> conv) {
    final userId = (context.read<AuthCubit>().state as AuthAuthenticated?)?.userId;
    if (conv['participant_a_id'].toString() == userId) {
      return conv['participant_b_name'] as String? ?? 'User';
    }
    return conv['participant_a_name'] as String? ?? 'User';
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Messages',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: GoogleFonts.urbanist(
                    color: AppColors.textTertiary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textTertiary, size: 20),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.secondary)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 2),
                            itemBuilder: (_, i) {
                              final conv = _filtered[i];
                              final name = _otherName(conv);
                              final initial = name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?';
                              return _ChatTile(
                                name: name,
                                initial: initial,
                                lastMessage:
                                    conv['last_message'] as String? ?? '',
                                time: _timeAgo(conv['updated_at'] as String? ??
                                    conv['created_at'] as String?),
                                unread: 0,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId:
                                          conv['id'].toString(),
                                      otherPersonName: name,
                                      otherPersonInitial: initial,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
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
          const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.accent, size: 64),
          const SizedBox(height: 16),
          Text('No Conversations Yet',
              style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          Text('Message a property agent to get started',
              style: GoogleFonts.urbanist(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String initial;
  final String lastMessage;
  final String time;
  final int unread;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.initial,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.secondary.withOpacity(0.15),
          child: Text(initial,
              style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark)),
            Text(time,
                style: GoogleFonts.urbanist(
                    fontSize: 11,
                    color: hasUnread
                        ? AppColors.secondary
                        : AppColors.textTertiary,
                    fontWeight:
                        hasUnread ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
        subtitle: lastMessage.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: hasUnread
                                  ? AppColors.dark
                                  : AppColors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400)),
                    ),
                    if (hasUnread)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$unread',
                              style: GoogleFonts.urbanist(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
