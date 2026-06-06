// lib/screens/aeps/aeps_history_screen.dart
import 'package:flutter/material.dart';
import '../../services/AEPS/api_service.dart';
import 'aeps_status_screen.dart';
import 'aeps_receipt_screen.dart';

class AepsHistoryScreen extends StatefulWidget {
  const AepsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AepsHistoryScreen> createState() => _AepsHistoryScreenState();
}

class _AepsHistoryScreenState extends State<AepsHistoryScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filtered     = [];

  bool _loading    = true;
  bool _loadingMore = false;
  bool _hasMore    = true;

  int _offset = 0;
  static const int _limit = 20;

  // Filters
  String _selectedStatus = 'ALL';
  String _selectedType   = 'ALL';
  String _searchQuery    = '';

  final List<String> _statusFilters = ['ALL', 'SUCCESS', 'PENDING', 'FAILED'];
  final Map<String, String> _typeFilters = {
    'ALL':              'All Types',
    'CW':  'Cash Withdrawal',
    'BE':  'Balance Enquiry',
    'MS':  'Mini Statement',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _offset  = 0;
      _hasMore = true;
      _transactions.clear();
    });
    try {
      final response = await _apiService.getAepsHistory(limit: _limit, offset: 0);
      final list = _parseList(response);
      setState(() {
        _transactions = list;
        _offset = list.length;
        _hasMore = list.length == _limit;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('AEPS history load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final response = await _apiService.getAepsHistory(limit: _limit, offset: _offset);
      final list = _parseList(response);
      setState(() {
        _transactions.addAll(list);
        _offset += list.length;
        _hasMore = list.length == _limit;
        _loadingMore = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> _parseList(Map<String, dynamic> response) {
    if (response["success"] != true) {
      debugPrint("AEPS history error: ${response["message"]}");
      return [];
    }
    final data = response["data"];
    // Shape 1: { success: true, data: [ ...transactions ] }
    if (data is List) return data.cast<Map<String, dynamic>>();
    // Shape 2: { success: true, data: { transactions: [...] } }
    if (data is Map && data["transactions"] is List) {
      return (data["transactions"] as List).cast<Map<String, dynamic>>();
    }
    // Shape 3: { success: true, transactions: [...] }  (flat)
    if (response["transactions"] is List) {
      return (response["transactions"] as List).cast<Map<String, dynamic>>();
    }
    debugPrint("AEPS history: unexpected shape: $response");
    return [];
  }

  void _applyFilters() {
    setState(() {
      _filtered = _transactions.where((tx) {
        final status = (tx['status'] ?? '').toString().toUpperCase();
        final type   = (tx['transactionType'] ?? '').toString().toUpperCase();
        final query  = _searchQuery.toLowerCase();

        final statusMatch = _selectedStatus == 'ALL' || status == _selectedStatus;
        final typeMatch   = _selectedType == 'ALL'   || type == _selectedType;
        final searchMatch = query.isEmpty ||
            (tx['txnRefId'] ?? '').toString().toLowerCase().contains(query) ||
            (tx['rrn'] ?? '').toString().toLowerCase().contains(query) ||
            (tx['bankName'] ?? '').toString().toLowerCase().contains(query) ||
            (tx['merchantRefId'] ?? '').toString().toLowerCase().contains(query);

        return statusMatch && typeMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('AEPS Transactions'),
        backgroundColor: const Color(0xFF0D6B4F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildSearchBar(),
        ),
      ),
      body: Column(
        children: [
          _buildFilterStrip(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF0D6B4F),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: (v) {
          _searchQuery = v;
          _applyFilters();
        },
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by Ref ID, RRN, Bank, Mobile...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final selected = _selectedStatus == s;
                Color chipColor;
                switch (s) {
                  case 'SUCCESS': chipColor = const Color(0xFF0D6B4F); break;
                  case 'PENDING': chipColor = Colors.orange.shade600; break;
                  case 'FAILED':  chipColor = Colors.red.shade600; break;
                  default:        chipColor = const Color(0xFF0D6B4F);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s, style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : chipColor,
                      fontWeight: FontWeight.w600,
                    )),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = s);
                      _applyFilters();
                    },
                    backgroundColor: chipColor.withOpacity(0.08),
                    selectedColor: chipColor,
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: chipColor.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Type filter dropdown
          Row(
            children: [
              const Icon(Icons.filter_list, size: 16, color: Color(0xFF0D6B4F)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isDense: true,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedType = v);
                      _applyFilters();
                    },
                    items: _typeFilters.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                  ),
                ),
              ),
              // Summary count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6B4F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filtered.length} records',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF0D6B4F), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0D6B4F)),
            SizedBox(height: 16),
            Text('Loading transactions...', style: TextStyle(color: Color(0xFF0D6B4F))),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _transactions.isEmpty ? 'No transactions yet' : 'No transactions match your filter',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            if (_transactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = 'ALL';
                    _selectedType   = 'ALL';
                    _searchQuery    = '';
                  });
                  _applyFilters();
                },
                child: const Text('Clear Filters', style: TextStyle(color: Color(0xFF0D6B4F))),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0D6B4F),
      onRefresh: _loadHistory,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _filtered.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _filtered.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0D6B4F))),
            );
          }
          return _buildTransactionCard(_filtered[i]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final status = (tx['status'] ?? '').toString().toUpperCase();
    final type   = (tx['transactionType'] ?? '').toString().toUpperCase();

    final isSuccess = status == 'SUCCESS';
    final isFailed  = status == 'FAILED';

    Color statusColor;
    IconData statusIcon;
    if (isSuccess) {
      statusColor = const Color(0xFF0D6B4F);
      statusIcon  = Icons.check_circle_rounded;
    } else if (isFailed) {
      statusColor = Colors.red.shade600;
      statusIcon  = Icons.cancel_rounded;
    } else {
      statusColor = Colors.orange.shade600;
      statusIcon  = Icons.hourglass_top_rounded;
    }

    IconData typeIcon;
    String typeLabel;
    switch (type) {
      case 'CW':
        typeIcon  = Icons.payments_rounded;
        typeLabel = 'Cash Withdrawal';
        break;
      case 'BE':
        typeIcon  = Icons.account_balance_wallet_rounded;
        typeLabel = 'Balance Enquiry';
        break;
      case 'MS':
        typeIcon  = Icons.receipt_long_rounded;
        typeLabel = 'Mini Statement';
        break;
      default:
        typeIcon  = Icons.fingerprint;
        typeLabel = type.isNotEmpty ? type : 'AEPS';
    }

    return GestureDetector(
      onTap: () => _openTransaction(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              // Type icon
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: statusColor, size: 24),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(typeLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A))),
                          ),
                          if (type == 'CASH_WITHDRAWAL' && tx['amount'] != null)
                            Text('₹${tx['amount']}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RRN: ${tx['rrn'] ?? 'N/A'}  ·  ${_formatDateShort(tx['createdAt'] ?? tx['timestamp'])}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx['bankName'] ?? tx['bankIin'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(status,
                            style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          // View receipt badge (SUCCESS only)
                          if (isSuccess)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6B4F).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.receipt_outlined, size: 12, color: Color(0xFF0D6B4F)),
                                  SizedBox(width: 3),
                                  Text('Receipt', style: TextStyle(fontSize: 11, color: Color(0xFF0D6B4F), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Map DB short codes to full names for AepsStatusScreen
  String _mapTxnType(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'CW': return 'CASH_WITHDRAWAL';
      case 'BE': return 'BALANCE_ENQUIRY';
      case 'MS': return 'MINI_STATEMENT';
      default:   return 'CASH_WITHDRAWAL';
    }
  }

  void _openTransaction(Map<String, dynamic> tx) {
    final status = (tx['status'] ?? '').toString().toUpperCase();
    final refId  = tx['merchantRefId']?.toString() ?? '';

    if (status == 'SUCCESS') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AepsReceiptScreen(
          txnRefId: refId,
          transactionData: tx,
        ),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AepsStatusScreen(
          txnRefId: refId,
          transactionType: _mapTxnType(tx['transactionType']?.toString()),
          amount: double.tryParse(tx['amount']?.toString() ?? '0') ?? 0,
        ),
      ));
    }
  }

  String _formatDateShort(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return dateTime.toString();
    }
  }
}