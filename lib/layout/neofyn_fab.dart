// ─────────────────────────────────────────────────────────────────────────────
//  neofyn_fab.dart
//
//  Drop-in glassmorphism SpeedDial for Neofyn Bharath.
//  Add to pubspec.yaml:
//      flutter_speed_dial: ^7.0.0
//
//  Usage inside your UserHomeScreen Scaffold:
//      floatingActionButton: const NeofynFab(),
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

// ── Brand tokens (same as rest of app) ───────────────────────────────────────
class _N {
  static const bg      = Color(0xFF1C0F06);
  static const caramel = Color(0xFFC8956C);
  static const glass   = Color(0x14FFFFFF);
  static const glassBd = Color(0x22FFFFFF);

  // child colours — each service has its own warm accent
  static const home     = Color(0xFFC8956C); // caramel   — Home
  static const wallet   = Color(0xFF7B9FE0); // slate blue — Wallet
  static const settings = Color(0xFFB58FDB); // soft purple — Settings
  static const profile  = Color(0xFF7DC97D); // sage green — Profile
}

// ─────────────────────────────────────────────────────────────────────────────
//  NEOFYN FAB  (stateful so we can react to open/close for overlay colour)
// ─────────────────────────────────────────────────────────────────────────────
class NeofynFab extends StatefulWidget {
  /// Callbacks are optional — wire up your own navigation here.
  final VoidCallback? onHome;
  final VoidCallback? onWallet;
  final VoidCallback? onSettings;
  final VoidCallback? onProfile;

  const NeofynFab({
    super.key,
    this.onHome,
    this.onWallet,
    this.onSettings,
    this.onProfile,
  });

  @override
  State<NeofynFab> createState() => _NeofynFabState();
}

class _NeofynFabState extends State<NeofynFab>
    with SingleTickerProviderStateMixin {

  // Controls the open/closed state — SpeedDial reads this ValueNotifier.
  final _isOpen = ValueNotifier<bool>(false);

  // Rotation animation for the main FAB icon.
  late final AnimationController _rotationCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _rotation = Tween<double>(begin: 0, end: 0.125) // 45 ° = 0.125 turns
      .animate(CurvedAnimation(parent: _rotationCtrl, curve: Curves.easeInOutCubic));

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _isOpen.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      // ── Open/close value notifier ──────────────────────────────────────
      openCloseDial: _isOpen,

      // ── Overlay — warm espresso tint matching the brand ────────────────
      overlayColor: const Color(0xFF0A0502),
      overlayOpacity: 0.72,

      // ── Spacing between children ───────────────────────────────────────
      spacing: 12,
      spaceBetweenChildren: 10,

      // ── Child entry animation ─────────────────────────────────────────
      animationDuration: const Duration(milliseconds: 260),
      animationCurve: Curves.easeOutCubic,

      // ── Main button ────────────────────────────────────────────────────
      backgroundColor: _N.caramel,
      foregroundColor: _N.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      // Elevation removed — we rely on the overlay for depth feel.
      elevation: 0,
      renderOverlay: true,

      onOpen: () {
        HapticFeedback.mediumImpact();
        _rotationCtrl.forward();
        setState(() {});
      },
      onClose: () {
        HapticFeedback.lightImpact();
        _rotationCtrl.reverse();
        setState(() {});
      },

      // ── Animated "+" → "×" icon ────────────────────────────────────────
      child: RotationTransition(
        turns: _rotation,
        child: const Icon(Icons.add_rounded, size: 28),
      ),

      // ── Child buttons ──────────────────────────────────────────────────
      children: [
        _buildChild(
          icon:    Icons.home_rounded,
          label:   'Home',
          color:   _N.home,
          onTap:   () {
            HapticFeedback.selectionClick();
            widget.onHome?.call();
          },
        ),
        _buildChild(
          icon:    Icons.account_balance_wallet_outlined,
          label:   'Wallet',
          color:   _N.wallet,
          onTap:   () {
            HapticFeedback.selectionClick();
            widget.onWallet?.call();
          },
        ),
        _buildChild(
          icon:    Icons.settings_outlined,
          label:   'Settings',
          color:   _N.settings,
          onTap:   () {
            HapticFeedback.selectionClick();
            widget.onSettings?.call();
          },
        ),
        _buildChild(
          icon:    Icons.person_outline_rounded,
          label:   'Profile',
          color:   _N.profile,
          onTap:   () {
            HapticFeedback.selectionClick();
            widget.onProfile?.call();
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CHILD BUILDER
  //  Each child = glass icon tile  +  floating label pill
  // ─────────────────────────────────────────────────────────────────────────
  SpeedDialChild _buildChild({
    required IconData     icon,
    required String       label,
    required Color        color,
    required VoidCallback onTap,
  }) {
    return SpeedDialChild(
      // ── Icon container ── glass tile with per-service accent ───────────
      child: Icon(icon, color: color, size: 24),
      backgroundColor: color.withOpacity(0.16),
      foregroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.32), width: 1),
      ),
      elevation: 0,

      // ── Label pill ─────────────────────────────────────────────────────
      label: label,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      labelBackgroundColor: _N.glass,
      labelShadow: const [],   // no shadow — flat glass style
      // SpeedDial v7 exposes labelWidget for full custom labels:
      labelWidget: _LabelPill(label),

      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LABEL PILL — glass chip matching the rest of the Neofyn design language
// ─────────────────────────────────────────────────────────────────────────────
class _LabelPill extends StatelessWidget {
  final String text;
  const _LabelPill(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x12FFFFFF),
      border: Border.all(color: const Color(0x20FFFFFF)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOW TO USE IN UserHomeScreen
// ─────────────────────────────────────────────────────────────────────────────
//
//  Inside _UserHomeScreenState.build(), replace the existing
//  floatingActionButton with:
//
//    floatingActionButton: NeofynFab(
//      onHome: () => setState(() => _selectedIndex = 0),
//      onWallet: () {
//        // open wallet sheet or navigate
//        showAddFundSheet(context, _walletProvider.userId);
//      },
//      onSettings: () {
//        // navigate to settings page
//        Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
//      },
//      onProfile: () => setState(() => _selectedIndex = 2),
//    ),
//
//  Also add this to your Scaffold to keep the FAB above the bottom nav:
//    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//
// ─────────────────────────────────────────────────────────────────────────────