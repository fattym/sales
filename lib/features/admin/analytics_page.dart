import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _supabase = Supabase.instance.client;
  static const Set<String> _activePipelineStages = {
    'lead',
    'contacted',
    'meeting_scheduled',
    'sample_issued',
    'quotation_sent',
    'decision_pending',
    'negotiation',
  };

  bool _isLoading = true;

  // Task metrics
  int _openTasks = 0;
  int _inProgressTasks = 0;
  int _closedTasks = 0;

  // Revenue metrics (Orders)
  double _approvedRevenue = 0;
  double _pendingRevenue = 0;

  // Sales metrics (School Sales)
  double _wonSales = 0;
  double _pipelineSales = 0;

  // Global metrics
  int _totalUsers = 0;
  int _totalSchools = 0;
  List<FlSpot> _userGrowthSpots = [];
  double _maxUserCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      // Fetch Tasks
      final tasks = await _supabase.from('tasks').select('status');
      int open = 0, inProgress = 0, closed = 0;
      for (var task in tasks) {
        if (task['status'] == 'open') open++;
        if (task['status'] == 'in_progress') inProgress++;
        if (task['status'] == 'closed') closed++;
      }

      // Fetch Orders for Revenue Analysis
      final orders = await _supabase
          .from('orders')
          .select('checkout_amount, status');
      double approved = 0, pending = 0;
      for (var order in orders) {
        final amount = (order['checkout_amount'] as num?)?.toDouble() ?? 0.0;
        if (order['status'] == 'approved' || order['status'] == 'paid') {
          approved += amount;
        } else {
          pending += amount;
        }
      }

      // Fetch School Sales for Pipeline Analysis
      final sales = await _supabase
          .from('school_sales')
          .select('expected_value, sale_status');
      double wonSales = 0, pipelineSales = 0;
      for (var sale in sales) {
        final amount = (sale['expected_value'] as num?)?.toDouble() ?? 0.0;
        final stage = (sale['sale_status'] as String?)?.toLowerCase() ?? '';
        if (stage == 'won') {
          wonSales += amount;
        } else if (_activePipelineStages.contains(stage)) {
          pipelineSales += amount;
        }
      }

      // Fetch Global counts and User Growth
      final usersRes = await _supabase.from('users').select('id, created_at');
      final schoolsRes = await _supabase.from('schools').select('id');

      // Calculate User Growth
      int currentYear = DateTime.now().year;
      List<int> monthlyCounts = List.filled(12, 0);
      int cumulativePrevYears = 0;

      for (var u in usersRes) {
        if (u['created_at'] != null) {
          DateTime date = DateTime.parse(u['created_at']);
          if (date.year == currentYear) {
            monthlyCounts[date.month - 1]++;
          } else if (date.year < currentYear) {
            cumulativePrevYears++;
          }
        }
      }

      List<FlSpot> growthSpots = [];
      int cumulative = cumulativePrevYears;
      for (int i = 0; i < 12; i++) {
        cumulative += monthlyCounts[i];
        growthSpots.add(FlSpot(i.toDouble(), cumulative.toDouble()));
      }

      if (mounted) {
        setState(() {
          _openTasks = open;
          _inProgressTasks = inProgress;
          _closedTasks = closed;
          _approvedRevenue = approved;
          _pendingRevenue = pending;
          _wonSales = wonSales;
          _pipelineSales = pipelineSales;
          _totalUsers = usersRes.length;
          _totalSchools = schoolsRes.length;
          _userGrowthSpots = growthSpots;
          _maxUserCount = cumulative.toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchAnalyticsData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(isDesktop),
                          const SizedBox(height: 32),
                          if (isDesktop) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'User Growth (Current Year)',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildUserGrowthChart(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Orders Revenue Overview',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildRevenueBarChart(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sales Pipeline Value',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSalesPipelineChart(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Task Status Breakdown',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTaskPieChart(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const Text(
                              'User Growth (Current Year)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildUserGrowthChart(),
                            const SizedBox(height: 32),
                            const Text(
                              'Orders Revenue Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRevenueBarChart(),
                            const SizedBox(height: 32),
                            const Text(
                              'Sales Pipeline Value',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSalesPipelineChart(),
                            const SizedBox(height: 32),
                            const Text(
                              'Task Status Breakdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTaskPieChart(),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildUserGrowthChart() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine:
                    (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const months = [
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'May',
                        'Jun',
                        'Jul',
                        'Aug',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Dec',
                      ];
                      // Display every other month to prevent crowding
                      if (value >= 0 && value < 12 && value.toInt() % 2 == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            months[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value == value.toInt()) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY:
                  _maxUserCount > 0
                      ? _maxUserCount + (_maxUserCount * 0.2)
                      : 10,
              lineBarsData: [
                LineChartBarData(
                  spots: _userGrowthSpots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueBarChart() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Approved/Paid');
                        case 1:
                          return const Text('Pending');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ), // Hide Y-axis to save space
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: _approvedRevenue,
                      color: Colors.green,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: _pendingRevenue,
                      color: Colors.orange,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesPipelineChart() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Won');
                        case 1:
                          return const Text('Pipeline');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: _wonSales,
                      color: Colors.teal,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: _pipelineSales,
                      color: Colors.purple,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskPieChart() {
    if (_openTasks == 0 && _inProgressTasks == 0 && _closedTasks == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No tasks available')),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              if (_openTasks > 0)
                PieChartSectionData(
                  color: Colors.blue,
                  value: _openTasks.toDouble(),
                  title: 'Open\n$_openTasks',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (_inProgressTasks > 0)
                PieChartSectionData(
                  color: Colors.amber,
                  value: _inProgressTasks.toDouble(),
                  title: 'In Prog\n$_inProgressTasks',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (_closedTasks > 0)
                PieChartSectionData(
                  color: Colors.green,
                  value: _closedTasks.toDouble(),
                  title: 'Closed\n$_closedTasks',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.5 : 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Users',
          '$_totalUsers',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Schools',
          '$_totalSchools',
          Icons.school,
          Colors.orange,
        ),
        _buildStatCard(
          'Approved Orders',
          'KES ${_approvedRevenue.toStringAsFixed(0)}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Pipeline Sales',
          'KES ${_pipelineSales.toStringAsFixed(0)}',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
