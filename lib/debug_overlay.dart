import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'debug_logger.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _visible = false;
  Offset _position = const Offset(16, 100);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Floating toggle button (drag to move)
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (d) => setState(() =>
              _position = Offset(
                (_position.dx + d.delta.dx).clamp(0, MediaQuery.of(context).size.width - 48),
                (_position.dy + d.delta.dy).clamp(0, MediaQuery.of(context).size.height - 48),
              )
            ),
            onTap: () => setState(() => _visible = !_visible),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.greenAccent, width: 1.5),
              ),
              child: const Icon(Icons.bug_report, color: Colors.greenAccent, size: 22),
            ),
          ),
        ),

        // Log panel
        if (_visible)
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: _LogPanel(onClose: () => setState(() => _visible = false)),
          ),
      ],
    );
  }
}

class _LogPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _LogPanel({required this.onClose});

  @override
  State<_LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<_LogPanel> {
  final _scroll = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.greenAccent.withOpacity(0.4), width: 1)),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.greenAccent, size: 14),
                const SizedBox(width: 6),
                const Text('Debug Log',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                // Copy all logs
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white54, size: 16),
                  tooltip: 'Copy all',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: DebugLogger.logs.join('\n'),
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logs copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                // Clear logs
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 16),
                  tooltip: 'Clear',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => setState(() => DebugLogger.clear()),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: DebugLogger.stream,
              initialData: DebugLogger.logs,
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                _scrollToBottom();
                if (logs.isEmpty) {
                  return const Center(
                    child: Text('No logs yet',
                      style: TextStyle(color: Colors.white24, fontSize: 12)),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    Color color = Colors.white70;
                    if (log.contains('❌') || log.contains('NULL')) color = const Color(0xFFFF5555);
                    if (log.contains('✅') || log.contains('✓') || log.contains('💾')) color = const Color(0xFF55FF55);
                    if (log.contains('⚠️')) color = const Color(0xFFFFAA00);
                    if (log.contains('📤') || log.contains('📥')) color = const Color(0xFF55AAFF);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(log,
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}