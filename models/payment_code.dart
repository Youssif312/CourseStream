class PaymentCode {
  final String code;
  final double amount;
  bool used;
  String? usedBy;
  String createdAt;
  String? usedAt;

  PaymentCode({
    required this.code,
    required this.amount,
    this.used = false,
    this.usedBy,
    required this.createdAt,
    this.usedAt,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'amount': amount,
    'used': used,
    'usedBy': usedBy,
    'createdAt': createdAt,
    'usedAt': usedAt,
  };

  static PaymentCode fromJson(Map<String, dynamic> j) => PaymentCode(
    code: j['code'],
    amount: (j['amount'] ?? 0.0) * 1.0,
    used: j['used'] ?? false,
    usedBy: j['usedBy'],
    createdAt: j['createdAt'],
    usedAt: j['usedAt'],
  );
}
