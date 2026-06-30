import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/payment_repository.dart';
import '../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PaymentSheet — full MoMo / Airtel payment flow as a bottom sheet.
//
// Usage:
//   await showPaymentSheet(
//     context: context,
//     amount: 5000,
//     type: 'unlock_property',
//     propertyId: p.id,
//     description: 'Unlock: ${p.title}',
//     onSuccess: () { setState(() => _unlocked = true); },
//   );
// ──────────────────────────────────────────────────────────────────────────────

Future<void> showPaymentSheet({
  required BuildContext context,
  required int amount,
  required String type,
  required String description,
  String? propertyId,
  VoidCallback? onSuccess,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => PaymentSheet(
      amount: amount,
      type: type,
      description: description,
      propertyId: propertyId,
      onSuccess: onSuccess,
    ),
  );
}

enum _Phase { input, polling, success, error }

class PaymentSheet extends StatefulWidget {
  final int amount;
  final String type;
  final String description;
  final String? propertyId;
  final VoidCallback? onSuccess;

  const PaymentSheet({
    super.key,
    required this.amount,
    required this.type,
    required this.description,
    this.propertyId,
    this.onSuccess,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  _Phase _phase = _Phase.input;
  String _method = 'mtn_momo';
  final _phoneCtrl = TextEditingController(text: '256');
  bool _submitting = false;
  String _errorMsg = '';

  // Polling state
  String? _paymentId;
  String? _providerRef;
  int _pollCount = 0;
  static const _maxPolls = 20; // 20 × 3s = 60s
  int _remainingSeconds = 60;
  Timer? _pollTimer;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _formattedAmount {
    final n = widget.amount;
    if (n >= 1000000) return 'UGX ${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return 'UGX ${(n / 1000).toStringAsFixed(0)},000';
    return 'UGX $n';
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length < 9) {
      _showError('Enter a valid phone number (e.g. 256701234567)');
      return;
    }
    setState(() { _submitting = true; _errorMsg = ''; });

    try {
      final result = await const PaymentRepository().initiatePayment(
        type: widget.type,
        method: _method,
        amount: widget.amount.toDouble(),
        phoneNumber: phone,
        propertyId: widget.propertyId,
        description: widget.description,
      );

      _paymentId = result['id']?.toString();
      _providerRef = result['provider_ref']?.toString();
      final status = result['status']?.toString() ?? '';

      if (status == 'success') {
        _onSuccess();
        return;
      }

      setState(() {
        _phase = _Phase.polling;
        _submitting = false;
        _remainingSeconds = 60;
        _pollCount = 0;
      });

      _startPolling();
      _startCountdown();
    } on Exception catch (e) {
      setState(() {
        _submitting = false;
        _phase = _Phase.error;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_paymentId == null || !mounted) return;
      _pollCount++;
      try {
        final result =
            await const PaymentRepository().getPayment(_paymentId!);
        final status = result['status']?.toString() ?? '';
        if (status == 'success') {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          _onSuccess();
        } else if (status == 'failed') {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            setState(() {
              _phase = _Phase.error;
              _errorMsg = 'Payment was declined. Please try again.';
            });
          }
        } else if (_pollCount >= _maxPolls) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            setState(() {
              _phase = _Phase.error;
              _errorMsg =
                  'Payment timed out. If you approved on your phone, try again in a moment.';
            });
          }
        }
      } catch (_) {
        // Ignore poll errors, keep retrying
      }
    });
  }

  void _startCountdown() {
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingSeconds = (_remainingSeconds - 1).clamp(0, 60));
    });
  }

  Future<void> _simulateSuccess() async {
    if (_providerRef == null) return;
    setState(() => _submitting = true);
    try {
      await const PaymentRepository().simulateSuccess(_providerRef!);
      // Give backend a moment to process
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _pollTimer?.cancel();
      _countdownTimer?.cancel();
      _onSuccess();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onSuccess() {
    if (!mounted) return;
    setState(() => _phase = _Phase.success);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess?.call();
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.urbanist(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom + 20;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: switch (_phase) {
          _Phase.input => _buildInput(),
          _Phase.polling => _buildPolling(),
          _Phase.success => _buildSuccess(),
          _Phase.error => _buildError(),
        },
      ),
    );
  }

  // ── Phase 1: Input ─────────────────────────────────────────────────────────
  Widget _buildInput() {
    return Column(
      key: const ValueKey('input'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const SizedBox(height: 16),

        // Title + amount
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete Payment',
                      style: GoogleFonts.urbanist(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF222222))),
                  const SizedBox(height: 4),
                  Text(widget.description,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF717171))),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_formattedAmount,
                  style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Payment method selector
        const Text('Payment Method',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222))),
        const SizedBox(height: 10),
        Row(
          children: [
            _methodTile('mtn_momo', 'MTN MoMo', const Color(0xFFFFCC00),
                Icons.phone_android_rounded),
            const SizedBox(width: 10),
            _methodTile('airtel_money', 'Airtel Money', const Color(0xFFFF1F0F),
                Icons.signal_cellular_alt_rounded),
          ],
        ),

        const SizedBox(height: 20),

        // Phone number
        const Text('Mobile Money Number',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                      right: BorderSide(color: Color(0xFFE0E0E0))),
                ),
                child: const Text('🇺🇬  +256',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222))),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF222222)),
                  decoration: const InputDecoration(
                    hintText: '701234567',
                    hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 13, color: Color(0xFF999999)),
            const SizedBox(width: 5),
            Text(
              _method == 'mtn_momo'
                  ? 'You will receive a MoMo prompt on this number'
                  : 'You will receive an Airtel Money prompt on this number',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF999999)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Pay button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text('Pay $_formattedAmount',
                    style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),

        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: Color(0xFFAAAAAA)),
            SizedBox(width: 4),
            Text('Payments are secure and encrypted',
                style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
          ],
        ),
      ],
    );
  }

  Widget _methodTile(String key, String label, Color color, IconData icon) {
    final active = _method == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _method = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? color : const Color(0xFFE0E0E0),
                width: active ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: active ? color : const Color(0xFF222222))),
              ),
              if (active)
                Icon(Icons.check_circle_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Phase 2: Polling ───────────────────────────────────────────────────────
  Widget _buildPolling() {
    final isMtn = _method == 'mtn_momo';
    return Column(
      key: const ValueKey('polling'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(),
        const SizedBox(height: 24),

        // Provider icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: isMtn
                ? const Color(0xFFFFCC00).withValues(alpha: 0.12)
                : const Color(0xFFFF1F0F).withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.phone_android_rounded,
            size: 36,
            color: isMtn ? const Color(0xFFFFCC00) : const Color(0xFFFF1F0F),
          ),
        ),
        const SizedBox(height: 20),

        Text(isMtn ? 'MTN MoMo Pending' : 'Airtel Money Pending',
            style: GoogleFonts.urbanist(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF222222))),
        const SizedBox(height: 8),
        Text(
          'A payment request of $_formattedAmount has been sent to\n+${_phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF717171), height: 1.5),
        ),

        const SizedBox(height: 20),
        const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
        const SizedBox(height: 10),
        Text(
          'Waiting for confirmation... $_remainingSeconds s',
          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),

        const SizedBox(height: 28),

        // Step instructions
        _stepRow('1', 'Open MTN MoMo / Airtel Money on your phone'),
        const SizedBox(height: 10),
        _stepRow('2', 'Approve the payment of $_formattedAmount'),
        const SizedBox(height: 10),
        _stepRow('3', 'Enter your PIN to confirm'),

        const SizedBox(height: 28),

        // Sandbox simulate button
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.science_rounded, size: 15, color: Color(0xFF999999)),
                  SizedBox(width: 6),
                  Text('Sandbox / Testing',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF999999))),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: _submitting ? null : _simulateSuccess,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary))
                      : const Text('Simulate Payment Success',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRow(String n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryFaint,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(n,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF444444), height: 1.4)),
        ),
      ],
    );
  }

  // ── Phase 3: Success ───────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              color: AppColors.success, size: 44),
        ),
        const SizedBox(height: 18),
        Text('Payment Confirmed!',
            style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF222222))),
        const SizedBox(height: 6),
        Text(_formattedAmount,
            style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.success)),
        const SizedBox(height: 28),
      ],
    );
  }

  // ── Phase 4: Error ─────────────────────────────────────────────────────────
  Widget _buildError() {
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(),
        const SizedBox(height: 24),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.close_rounded,
              color: AppColors.error, size: 38),
        ),
        const SizedBox(height: 16),
        Text('Payment Failed',
            style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF222222))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(_errorMsg.isNotEmpty ? _errorMsg : 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF717171), height: 1.5)),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => setState(() {
              _phase = _Phase.input;
              _errorMsg = '';
              _pollCount = 0;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text('Try Again',
                style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF717171))),
        ),
      ],
    );
  }

  Widget _handle() {
    return Center(
      child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(2))),
    );
  }
}
