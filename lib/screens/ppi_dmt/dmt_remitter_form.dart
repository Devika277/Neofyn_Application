import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ppi_dmt/dmt_beneficiary_dashboard.dart';
import '../../providers/remitter_provider.dart';



import 'package:my_app/providers/beneficiary_provider.dart';
import 'package:my_app/providers/payout_provider.dart';
import 'package:my_app/models/beneficiary_model.dart';
import 'package:my_app/providers/wallet_provider.dart';
import 'package:my_app/screens/payout/payout_status_screen.dart';

// ─── Theme constants (unchanged) ────────────────────────────────────────────
const _bg        = Color(0xFF0D0D0D);
const _surface   = Color(0xFF1A1A1A);
const _card      = Color(0xFF222222);
const _green     = Color(0xFF00FF9D);
const _blue      = Color(0xFF3B82F6);
const _border    = Color(0xFF2A2A2A);
const _textPrim  = Colors.white;
const _textSec   = Color(0xFF888888);

// lib/screens/dmt/dmt_remitter_form.dart
class DmtRemitterFormPage extends StatefulWidget {
  final String phone;
  const DmtRemitterFormPage({required this.phone, super.key});
  @override
  State<DmtRemitterFormPage> createState() => _DmtRemitterFormPageState();
}

class _DmtRemitterFormPageState extends State<DmtRemitterFormPage> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Enter full name');
      return;
    }
    setState(() => _loading = true);
    await context.read<RemitterProvider>().registerRemitter({
      'mobile': widget.phone,
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });
    if (mounted) {
      Navigator.pushReplacement(context, _slide(DmtBeneficiaryDashboard(remitterPhone: widget.phone)));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _darkAppBar('Register for DMT'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _infoCard(
              icon: Icons.app_registration_rounded,
              color: _green,
              title: 'New Remitter',
              subtitle: 'Complete one‑time registration to enable money transfer.',
            ),
            const SizedBox(height: 24),
            _label('Full Name *'),
            const SizedBox(height: 8),
            _inputField(controller: _nameCtrl, hint: 'As per PAN / Aadhaar'),
            const SizedBox(height: 16),
            _label('Address (Optional)'),
            const SizedBox(height: 8),
            _inputField(controller: _addressCtrl, hint: 'Street, city'),
            const SizedBox(height: 32),
            _primaryButton(
              label: 'Register & Continue',
              loading: _loading,
              color: _green,
              onTap: _register,
            ),
          ],
        ),
      ),
    );
  }
void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
    ));
  }}



// ─────────────────────────────────────────────────────────────────────────────
// All shared UI helpers remain exactly the same as your original file
// ─────────────────────────────────────────────────────────────────────────────
// (Copy _darkAppBar, _label, _sectionHeader, _infoCard, _inputDecoration,
//  _inputField, _primaryButton, _outlineButton, _slide from your original file)
// ... (keep them unchanged)

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI helpers
// ─────────────────────────────────────────────────────────────────────────────
AppBar _darkAppBar(String title) => AppBar(
  backgroundColor: _surface,
  elevation: 0,
  centerTitle: true,
  title: Text(title,
      style: const TextStyle(color: _textPrim, fontSize: 16,
          fontWeight: FontWeight.w600)),
  iconTheme: const IconThemeData(color: _textPrim),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(height: 1, color: _border),
  ),
);

Widget _label(String text) => Text(text,
    style: const TextStyle(color: _textSec, fontSize: 12,
        fontWeight: FontWeight.w500, letterSpacing: 0.5));

Widget _sectionHeader(String text) => Row(
  children: [
    Container(width: 3, height: 16,
        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(color: _textPrim, fontSize: 14,
        fontWeight: FontWeight.w600)),
  ],
);

Widget _infoCard({
  required IconData icon, required Color color,
  required String title, required String subtitle,
}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: color.withOpacity(0.08),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: color.withOpacity(0.2)),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 13,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: _textSec, fontSize: 12,
                height: 1.4)),
          ],
        ),
      ),
    ],
  ),
);

InputDecoration _inputDecoration(String hint, {
  String? prefix, Widget? suffix,
}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: _textSec, fontSize: 14),
  prefixText: prefix,
  prefixStyle: const TextStyle(color: _textSec, fontSize: 14),
  suffixIcon: suffix,
  filled: true,
  fillColor: _surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _blue, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.redAccent),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
  ),
  counterText: '',
);

Widget _inputField({
  required TextEditingController controller,
  required String hint,
  String? prefix,
  Widget? suffix,
  bool obscure = false,
  int? maxLength,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) => TextField(
  controller: controller,
  obscureText: obscure,
  maxLength: maxLength,
  keyboardType: keyboardType,
  inputFormatters: inputFormatters,
  style: const TextStyle(color: _textPrim, fontSize: 14),
  decoration: _inputDecoration(hint, prefix: prefix, suffix: suffix),
);

Widget _primaryButton({
  required String label,
  required VoidCallback? onTap,
  required Color color,
  bool loading = false,
  IconData? icon,
}) => SizedBox(
  width: double.infinity,
  child: GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: onTap == null ? _textSec.withOpacity(0.2) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: onTap == null ? _textSec.withOpacity(0.3) : color.withOpacity(0.5),
        ),
      ),
      child: Center(
        child: loading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: color))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: onTap == null ? _textSec : color, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(label,
                      style: TextStyle(
                        color: onTap == null ? _textSec : color,
                        fontSize: 15, fontWeight: FontWeight.w600,
                      )),
                ],
              ),
      ),
    ),
  ),
);

Widget _outlineButton({required String label, required VoidCallback onTap}) =>
    SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(color: _textSec, fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );

PageRoute _slide(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 300),
);

