// lib/widgets/wallet_ledger_widget.dart
// Drop-in widget to show wallet_ledger entries as credit/debit list

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class WalletLedgerWidget extends StatelessWidget {
  const WalletLedgerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final ledger   = provider.ledger;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF9D)));
    }

    if (ledger.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text('No transactions yet', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount:   ledger.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white38, height: 1),
      itemBuilder: (_, i) {
        final entry = ledger[i] as Map<String, dynamic>;
        final isCredit  = entry['transaction_type'] == 'credit';
        final amount    = double.tryParse(entry['amount'].toString()) ?? 0;
        final balance   = double.tryParse(entry['balance_after'].toString()) ?? 0;
        final desc      = entry['description'] ?? '';
        final createdAt = entry['created_at'] != null
            ? DateTime.tryParse(entry['created_at'].toString())
            : null;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:  (isCredit ? const Color(0xFF00FF9D) : Colors.redAccent).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color:  isCredit ? const Color(0xFF00FF9D) : Colors.redAccent,
              size:   18,
            ),
          ),
          title: Text(
            desc,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: createdAt != null
              ? Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal()),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color:      isCredit ? const Color(0xFF00FF9D) : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize:   14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bal: ₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}