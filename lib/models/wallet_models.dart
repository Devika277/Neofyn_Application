class MainWallet {
  final double balance;
  MainWallet({required this.balance});
  factory MainWallet.fromJson(Map<String, dynamic> json) => MainWallet(
    balance: double.parse(json['balance'].toString()),  // ← toString() first
  );
}

class AepsWallet {
  final double balance;
  AepsWallet({required this.balance});
  factory AepsWallet.fromJson(Map<String, dynamic> json) => AepsWallet(
    balance: double.parse(json['balance'].toString()),  // ← toString() first
  );

}

class WalletStats {
  final double rewards;
  final double commission;
  final double ccBalance;
  WalletStats({required this.rewards, required this.commission, required this.ccBalance});
  factory WalletStats.fromJson(Map<String, dynamic> json) => WalletStats(
    rewards:    double.parse(json['rewards'].toString()),
    commission: double.parse(json['commission'].toString()),
    ccBalance:  double.parse(json['ccBalance'].toString()),
  );
}