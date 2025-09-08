import 'package:flutter/material.dart';
import '../../models/club_model.dart';
import '../../models/club_membership_model.dart';
import '../../models/club_payment_model.dart';
import '../../services/club_service.dart';
import '../../services/payment_service.dart';

class ClubAnalyticsPage extends StatefulWidget {
  final Club club;

  const ClubAnalyticsPage({Key? key, required this.club}) : super(key: key);

  @override
  State<ClubAnalyticsPage> createState() => _ClubAnalyticsPageState();
}

class _ClubAnalyticsPageState extends State<ClubAnalyticsPage> {
  final ClubService _clubService = ClubService();
  final PaymentService _paymentService = PaymentService();
  
  bool _isLoading = true;
  
  // Analytics Data
  List<ClubMembership> _members = [];
  List<ClubPayment> _payments = [];
  
  // Calculated Metrics
  int _totalMembers = 0;
  int _premiumMembers = 0;
  int _freeMembers = 0;
  double _totalRevenue = 0.0;
  double _monthlyRevenue = 0.0;
  double _authorEarnings = 0.0;
  
  Map<String, int> _membershipTrends = {}; // Month -> member count
  Map<String, double> _revenueTrends = {}; // Month -> revenue
  
  List<Map<String, dynamic>> _paymentMethods = [];
  double _averageRevenuePerUser = 0.0;
  int _newMembersThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load members and payments in parallel
      final results = await Future.wait([
        _clubService.getClubMembers(widget.club.id),
        _paymentService.getPaymentsByClub(widget.club.id),
      ]);
      
      _members = results[0] as List<ClubMembership>;
      _payments = results[1] as List<ClubPayment>;
      
      _calculateMetrics();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  void _calculateMetrics() {
    // Basic member counts
    _totalMembers = _members.length;
    _premiumMembers = _members.where((m) => m.membershipType == MembershipType.premium).length;
    _freeMembers = _totalMembers - _premiumMembers;
    
    // Revenue calculations
    final completedPayments = _payments.where((p) => p.isCompleted).toList();
    _totalRevenue = completedPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    _authorEarnings = _totalRevenue * 0.8; // 80% to author
    
    // Monthly revenue (current month)
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    _monthlyRevenue = completedPayments
        .where((p) => p.completedAt != null && p.completedAt!.isAfter(monthStart))
        .fold(0.0, (sum, payment) => sum + payment.amount);
    
    // Average revenue per user
    _averageRevenuePerUser = _premiumMembers > 0 ? _totalRevenue / _premiumMembers : 0.0;
    
    // New members this month
    _newMembersThisMonth = _members
        .where((m) => m.joinedAt.isAfter(monthStart))
        .length;
    
    // Payment methods distribution
    _calculatePaymentMethodStats();
    
    // Trends calculation
    _calculateTrends();
  }

  void _calculatePaymentMethodStats() {
    Map<PaymentMethod, int> methodCounts = {};
    Map<PaymentMethod, double> methodAmounts = {};
    
    final completedPayments = _payments.where((p) => p.isCompleted);
    
    for (final payment in completedPayments) {
      methodCounts[payment.paymentMethod] = (methodCounts[payment.paymentMethod] ?? 0) + 1;
      methodAmounts[payment.paymentMethod] = (methodAmounts[payment.paymentMethod] ?? 0.0) + payment.amount;
    }
    
    _paymentMethods = methodCounts.entries.map((entry) {
      return {
        'method': entry.key,
        'count': entry.value,
        'amount': methodAmounts[entry.key] ?? 0.0,
        'percentage': completedPayments.isNotEmpty ? (entry.value / completedPayments.length * 100) : 0.0,
      };
    }).toList();
    
    _paymentMethods.sort((a, b) => b['count'].compareTo(a['count']));
  }

  void _calculateTrends() {
    // Membership trends (last 6 months)
    final now = DateTime.now();
    _membershipTrends = {};
    _revenueTrends = {};
    
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final monthKey = '${monthDate.month}/${monthDate.year}';
      
      // Members joined in this month
      _membershipTrends[monthKey] = _members
          .where((m) => m.joinedAt.isAfter(monthDate) && m.joinedAt.isBefore(nextMonth))
          .length;
      
      // Revenue in this month
      _revenueTrends[monthKey] = _payments
          .where((p) => p.isCompleted && 
                       p.completedAt != null &&
                       p.completedAt!.isAfter(monthDate) && 
                       p.completedAt!.isBefore(nextMonth))
          .fold(0.0, (sum, payment) => sum + payment.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.club.name} - Analytics'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  _buildOverviewSection(),
                  const SizedBox(height: 24),
                  
                  // Revenue Section
                  _buildRevenueSection(),
                  const SizedBox(height: 24),
                  
                  // Membership Section
                  _buildMembershipSection(),
                  const SizedBox(height: 24),
                  
                  // Payment Methods Section
                  if (_paymentMethods.isNotEmpty) ...[
                    _buildPaymentMethodsSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Trends Section
                  _buildTrendsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Members',
                _totalMembers.toString(),
                Icons.people,
                Colors.blue,
                subtitle: '$_newMembersThisMonth new this month',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                '৳${_totalRevenue.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.green,
                subtitle: '৳${_monthlyRevenue.toStringAsFixed(2)} this month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Author Earnings',
                '৳${_authorEarnings.toStringAsFixed(2)}',
                Icons.person,
                Colors.purple,
                subtitle: '80% of total revenue',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Revenue/User',
                '৳${_averageRevenuePerUser.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
                subtitle: 'Premium members only',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildRevenueRow('Total Revenue', _totalRevenue, Colors.blue),
              const Divider(height: 20),
              _buildRevenueRow('Author Earnings (80%)', _authorEarnings, Colors.green),
              const Divider(height: 20),
              _buildRevenueRow('Platform Commission (20%)', _totalRevenue * 0.2, Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membership Distribution',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMembershipCard(
                'Premium Members',
                _premiumMembers,
                Colors.amber,
                Icons.star,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMembershipCard(
                'Free Members',
                _freeMembers,
                Colors.grey,
                Icons.person,
              ),
            ),
          ],
        ),
        if (_totalMembers > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conversion Rate',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _premiumMembers / _totalMembers,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_premiumMembers / _totalMembers * 100).toStringAsFixed(1)}% of members are premium',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _paymentMethods.map((method) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPaymentMethodColor(method['method']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPaymentMethodIcon(method['method']),
                        color: _getPaymentMethodColor(method['method']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPaymentMethodName(method['method']),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${method['count']} transactions • ৳${method['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${method['percentage'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trends (Last 6 Months)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Members by Month',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ..._membershipTrends.entries.map((entry) {
                final maxMembers = _membershipTrends.values.isNotEmpty ? 
                    _membershipTrends.values.reduce((a, b) => a > b ? a : b) : 1;
                final percentage = maxMembers > 0 ? entry.value / maxMembers : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              const Text(
                'Revenue by Month',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ..._revenueTrends.entries.map((entry) {
                final maxRevenue = _revenueTrends.values.isNotEmpty ? 
                    _revenueTrends.values.reduce((a, b) => a > b ? a : b) : 1.0;
                final percentage = maxRevenue > 0 ? entry.value / maxRevenue : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '৳${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          '৳${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return Colors.pink;
      case PaymentMethod.nagad:
        return Colors.orange;
      case PaymentMethod.rocket:
        return Colors.purple;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.bank_transfer:
        return Colors.green;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
      case PaymentMethod.nagad:
      case PaymentMethod.rocket:
        return Icons.phone_android;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.bank_transfer:
        return Icons.account_balance;
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return 'bKash';
      case PaymentMethod.nagad:
        return 'Nagad';
      case PaymentMethod.rocket:
        return 'Rocket';
      case PaymentMethod.card:
        return 'Card Payment';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
    }
  }
}
