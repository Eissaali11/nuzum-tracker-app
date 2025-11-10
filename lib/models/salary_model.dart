/// ============================================
/// 💰 نموذج الراتب - Salary Model
/// ============================================
class Salary {
  final String salaryId;
  final String month;
  final double amount;
  final String currency;
  final DateTime? paidDate;
  final SalaryStatus status;
  final SalaryDetails details;
  final String? notes;

  Salary({
    required this.salaryId,
    required this.month,
    required this.amount,
    required this.currency,
    this.paidDate,
    required this.status,
    required this.details,
    this.notes,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      salaryId: json['salary_id'] ?? '',
      month: json['month'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'SAR',
      paidDate: json['paid_date'] != null 
          ? DateTime.parse(json['paid_date']) 
          : null,
      status: SalaryStatus.fromString(json['status'] ?? 'pending'),
      details: SalaryDetails.fromJson(json['details'] ?? {}),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salary_id': salaryId,
      'month': month,
      'amount': amount,
      'currency': currency,
      'paid_date': paidDate?.toIso8601String(),
      'status': status.toString(),
      'details': details.toJson(),
      'notes': notes,
    };
  }
}

/// ============================================
/// 📊 تفاصيل الراتب - Salary Details
/// ============================================
class SalaryDetails {
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double bonuses;
  final double overtime;
  final double tax;

  SalaryDetails({
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.bonuses,
    required this.overtime,
    required this.tax,
  });

  factory SalaryDetails.fromJson(Map<String, dynamic> json) {
    return SalaryDetails(
      baseSalary: (json['base_salary'] ?? 0.0).toDouble(),
      allowances: (json['allowances'] ?? 0.0).toDouble(),
      deductions: (json['deductions'] ?? 0.0).toDouble(),
      bonuses: (json['bonuses'] ?? 0.0).toDouble(),
      overtime: (json['overtime'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_salary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'bonuses': bonuses,
      'overtime': overtime,
      'tax': tax,
    };
  }
}

/// ============================================
/// 💵 حالة الراتب - Salary Status
/// ============================================
enum SalaryStatus {
  paid,
  pending,
  cancelled;

  static SalaryStatus fromString(String value) {
    switch (value) {
      case 'paid':
        return SalaryStatus.paid;
      case 'pending':
        return SalaryStatus.pending;
      case 'cancelled':
        return SalaryStatus.cancelled;
      default:
        return SalaryStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case SalaryStatus.paid:
        return 'مدفوع';
      case SalaryStatus.pending:
        return 'معلق';
      case SalaryStatus.cancelled:
        return 'ملغي';
    }
  }
}

/// ============================================
/// 📈 ملخص الرواتب - Salary Summary
/// ============================================
class SalarySummary {
  final int totalSalaries;
  final double totalAmount;
  final double averageAmount;
  final double lastSalary;
  final DateTime? lastPaidDate;

  SalarySummary({
    required this.totalSalaries,
    required this.totalAmount,
    required this.averageAmount,
    required this.lastSalary,
    this.lastPaidDate,
  });

  factory SalarySummary.fromJson(Map<String, dynamic> json) {
    return SalarySummary(
      totalSalaries: json['total_salaries'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      averageAmount: (json['average_amount'] ?? 0.0).toDouble(),
      lastSalary: (json['last_salary'] ?? 0.0).toDouble(),
      lastPaidDate: json['last_paid_date'] != null 
          ? DateTime.parse(json['last_paid_date']) 
          : null,
    );
  }
}

