/// ============================================
/// 💳 نموذج الالتزام المالي - Liability Model
/// ============================================
class Liability {
  final int id;
  final String type; // 'advance', 'damage', 'debt'
  final String description;
  final double amount;
  final double paid;
  final double remaining;
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? dueDate;
  final double? monthlyInstallment;
  final int? remainingInstallments;

  Liability({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.paid,
    required this.remaining,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.monthlyInstallment,
    this.remainingInstallments,
  });

  factory Liability.fromJson(Map<String, dynamic> json) {
    return Liability(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      monthlyInstallment: json['monthly_installment'] != null
          ? (json['monthly_installment'] as num?)?.toDouble()
          : null,
      remainingInstallments: json['remaining_installments'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'paid': paid,
      'remaining': remaining,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'monthly_installment': monthlyInstallment,
      'remaining_installments': remainingInstallments,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'advance':
        return 'سلفة';
      case 'damage':
        return 'تلفية';
      case 'debt':
        return 'دين';
      default:
        return type;
    }
  }

  double get progressPercentage {
    if (amount == 0) return 0.0;
    return (paid / amount) * 100;
  }
}

/// ============================================
/// 📊 ملخص الالتزامات - Liabilities Summary
/// ============================================
class LiabilitiesSummary {
  final double totalLiabilities;
  final double totalPaid;
  final double totalRemaining;
  final List<Liability> liabilities;

  LiabilitiesSummary({
    required this.totalLiabilities,
    required this.totalPaid,
    required this.totalRemaining,
    required this.liabilities,
  });

  factory LiabilitiesSummary.fromJson(Map<String, dynamic> json) {
    return LiabilitiesSummary(
      totalLiabilities: (json['total_liabilities'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalRemaining: (json['total_remaining'] as num?)?.toDouble() ?? 0.0,
      liabilities: (json['liabilities'] as List?)
              ?.map((item) => Liability.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// ============================================
/// 💰 الملخص المالي - Financial Summary
/// ============================================
class FinancialSummary {
  final String employeeName;
  final String employeeNumber;
  final double currentSalary;
  final double totalLiabilities;
  final double netSalaryAfterDeductions;
  final List<Liability> activeAdvances;
  final List<Liability> activeDamages;

  FinancialSummary({
    required this.employeeName,
    required this.employeeNumber,
    required this.currentSalary,
    required this.totalLiabilities,
    required this.netSalaryAfterDeductions,
    required this.activeAdvances,
    required this.activeDamages,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      employeeName: json['employee_name'] as String? ?? '',
      employeeNumber: json['employee_number'] as String? ?? '',
      currentSalary: (json['current_salary'] as num?)?.toDouble() ?? 0.0,
      totalLiabilities: (json['total_liabilities'] as num?)?.toDouble() ?? 0.0,
      netSalaryAfterDeductions: (json['net_salary_after_deductions'] as num?)
              ?.toDouble() ??
          0.0,
      activeAdvances:
          (json['active_advances'] as List?)
              ?.map((item) => Liability.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      activeDamages:
          (json['active_damages'] as List?)
              ?.map((item) => Liability.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get deductionPercentage {
    if (currentSalary == 0) return 0.0;
    return (totalLiabilities / currentSalary) * 100;
  }
}
