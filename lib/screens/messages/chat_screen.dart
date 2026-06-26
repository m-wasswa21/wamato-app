import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/services/message_repository.dart';
import '../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherPersonName;
  final String otherPersonInitial;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherPersonName,
    required this.otherPersonInitial,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = MessageRepository();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _sending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) _currentUserId = auth.userId;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getMessages(widget.conversationId, size: 100);
      if (mounted) {
        setState(() {
          _messages = data;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    // Optimistic insert
    final optimistic = {
      'id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
      'content': text,
      'sender_id': _currentUserId ?? '',
      'created_at': DateTime.now().toIso8601String(),
      'pending': true,
    };
    setState(() => _messages.add(optimistic));
    _scrollToBottom();
    try {
      final sent = await _repo.sendMessage(widget.conversationId, text);
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == optimistic['id']);
          if (idx != -1) _messages[idx] = sent;
        });
      }
    } catch (_) {
      // Remove optimistic on failure
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m['id'] == optimistic['id']));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondary.withOpacity(0.15),
              child: Text(widget.otherPersonInitial,
                  style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.otherPersonName,
                  style: GoogleFonts.urbanist(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _messages.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _Bubble(
                          msg: _messages[i],
                          currentUserId: _currentUserId ?? '',
                          otherInitial: widget.otherPersonInitial,
                        ),
                      ),
          ),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: const Color(0xFFF8FAFC),
          child: Align(
            alignment: i.isEven ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 200,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
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
              color: AppColors.accent, size: 48),
          const SizedBox(height: 12),
          Text('No messages yet',
              style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
          const SizedBox(height: 6),
          Text('Send the first message!',
              style: GoogleFonts.urbanist(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: AppColors.dark.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              style:
                  GoogleFonts.urbanist(fontSize: 14, color: AppColors.dark),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.urbanist(
                    color: AppColors.textTertiary, fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: _sending
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary,
                  shape: BoxShape.circle),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : const Icon(Icons.send_rounded,
                      color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final String currentUserId;
  final String otherInitial;
  const _Bubble(
      {required this.msg,
      required this.currentUserId,
      required this.otherInitial});

  @override
  Widget build(BuildContext context) {
    final isMine = msg['sender_id'].toString() == currentUserId;
    final text = msg['content'] as String? ?? '';
    final isPending = msg['pending'] == true;

    final time = _formatTime(msg['created_at'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.secondary.withOpacity(0.15),
              child: Text(otherInitial,
                  style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary)),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? (isPending
                          ? AppColors.primary.withOpacity(0.6)
                          : AppColors.primary)
                      : AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.dark.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color:
                          isMine ? AppColors.white : AppColors.dark,
                      fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 3),
              Text(time,
                  style: GoogleFonts.urbanist(
                      fontSize: 10,
                      color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
    } catch (_) {
      return '';
    }
  }
}
