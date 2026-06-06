import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/aeps_provider.dart';
import '../../widgets/loading_widget.dart';

class BankListScreen extends StatefulWidget {
  const BankListScreen({super.key});

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadBanks();
  }
  
  Future<void> _loadBanks() async {
    final provider = Provider.of<AepsProvider>(context, listen: false);
    await provider.fetchBanks();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supported Banks'),
        backgroundColor: const Color(0xFF6200EE),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBanks,
          ),
        ],
      ),
      body: Consumer<AepsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Loading banks...');
          }
          
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBanks,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final filteredBanks = provider.banks.where((bank) {
            return _searchQuery.isEmpty ||
                bank.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                bank.code.contains(_searchQuery);
          }).toList();
          
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search bank by name or code...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              
              // Bank Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${filteredBanks.length} banks available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8),
              
              // Bank List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredBanks.length,
                  itemBuilder: (context, index) {
                    final bank = filteredBanks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6200EE).withOpacity(0.1),
                          child: Text(
                            bank.code,
                            style: const TextStyle(
                              color: Color(0xFF6200EE),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(bank.name),
                        subtitle: Text('Code: ${bank.code}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.content_copy, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bank code copied'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}