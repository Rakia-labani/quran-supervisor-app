// lib/screens/diagram_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/constants.dart';
import '../services/services.dart';
import '../services/api_exception.dart';
import '../widgets/shimmer_loading.dart';

// ✅ نوع المخطط: أعمدة أو دائري
enum _ChartType { bar, pie }

// عدد أجزاء القرآن الكريم الكلي — الأساس اللي منحسب عليه كل نسب الإنجاز
const int _kTotalParts = 30;

class DiagramScreen extends StatefulWidget {
  const DiagramScreen({super.key});

  @override
  _DiagramScreenState createState() => _DiagramScreenState();
}

class _DiagramScreenState extends State<DiagramScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _students = [];
  String _errorMessage = '';
  _ChartType _chartType = _ChartType.bar;

  // ✅ دوران أيقونة التحديث أثناء التحميل
  late final AnimationController _refreshIconController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  // ✅ ظهور متدرج لعناصر قائمة "تفاصيل الحفظ" لما البيانات توصل
  final Set<int> _revealedRanks = {};

  @override
  void initState() {
    super.initState();
    _fetchDiagramData();
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    super.dispose();
  }

  Future<void> _fetchDiagramData() async {
    _refreshIconController.repeat();
    try {
      final response = await ApiService.getDiagram();

      setState(() {
        _students = response['students'];
        _isLoading = false;
        _errorMessage = '';
      });
      _startRevealAnimation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      _refreshIconController.stop();
      _refreshIconController.value = 0;
    }
  }

  // ✅ كل صف بقائمة "تفاصيل الحفظ" بيظهر بعد يلي قبله بفارق بسيط
  void _startRevealAnimation() {
    _revealedRanks.clear();
    final count = _students.length;
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: 60 * i), () {
        if (mounted) setState(() => _revealedRanks.add(i));
      });
    }
  }

  String _getErrorMessage(dynamic error) => userMessageFor(error);

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _fetchDiagramData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/quran_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Text('مخطط الحفظ'),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: _refreshIconController,
              child: const Icon(Icons.refresh),
            ),
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading(
        child: SkeletonDiagram(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _refresh, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: AppColors.primaryColor),
            const SizedBox(height: 16),
            Text(
              'لسا ما في تحديثات حفظ اليوم',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'أول ما يصير تسجيل حفظ اليوم، رح يظهر هون فوراً',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _refresh, child: const Text('تحديث')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        // ✅ تمكين التمرير الكامل
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات المخطط
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              color: AppColors.surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'عدد الطالبات: ${_students.length}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'مخطط الحفظ',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ زر تبديل بين مخطط الأعمدة والمخطط الدائري
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              child: Row(
                children: [
                  _buildChartTypeChip('أعمدة', Icons.bar_chart, _ChartType.bar),
                  const SizedBox(width: 8),
                  _buildChartTypeChip('دائري', Icons.pie_chart, _ChartType.pie),
                ],
              ),
            ),

            // ✅ المخطط بارتفاع مريح وفاصل واضح
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: SizedBox(
                height: 350, // ارتفاع ثابت مريح للمخطط
                child: _chartType == _ChartType.bar
                    ? _buildChart()
                    : _buildPieChart(),
              ),
            ),

            const SizedBox(height: 20), // ✅ فصل واضح بين المخطط والجدول

            // ✅ قائمة "تفاصيل الحفظ" الجديدة: كروت ترتيب أنيقة بدل الجدول
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              color: AppColors.surfaceColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل الحفظ',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  _buildRankingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeChip(String label, IconData icon, _ChartType type) {
    final bool selected = _chartType == type;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? AppColors.primaryColor : AppColors.textSecondary,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _chartType = type),
      selectedColor: AppColors.primaryColor.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryColor : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  // ✅ نفس ألوان مخطط الأعمدة، معتمدة كمان بالمخطط الدائري وبقائمة الترتيب
  // حتى يبقى نفس لون الطالبة موحّد بكل مكان بالشاشة
  static const List<Color> _chartColors = [
    AppColors.primaryColor,
    AppColors.secondaryColor,
    AppColors.successColor,
    AppColors.warningColor,
    AppColors.accentColor,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  Widget _buildPieChart() {
    final sortedStudents = List<dynamic>.from(_students);
    sortedStudents.sort((a, b) => b['number'].compareTo(a['number']));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: sortedStudents.asMap().entries.map((entry) {
                final index = entry.key;
                final student = entry.value;
                final int value = (student['number'] as num).toInt();
                // ✅ النسبة المئوية هلق محسوبة من أصل 30 جزء (الحفظ الكامل)
                // مش من مجموع الطالبات، فكل طالبة نسبتها تعكس تقدّمها
                // الفعلي بغض النظر عن باقي الطالبات
                final int completionPercent =
                    ((value / _kTotalParts) * 100).round().clamp(0, 100);
                return PieChartSectionData(
                  color: _chartColors[index % _chartColors.length],
                  value: value.toDouble(),
                  title: '$completionPercent%',
                  radius: 90,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // ✅ دليل الألوان (الاسم + عدد الأجزاء + نسبة الإنجاز من 30)
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: sortedStudents.length,
            itemBuilder: (context, index) {
              final student = sortedStudents[index];
              final int value = (student['number'] as num).toInt();
              final int completionPercent =
                  ((value / _kTotalParts) * 100).round().clamp(0, 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartColors[index % _chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${student['name']} — '),
                            // ✅ Directionality.ltr للجزء الرقمي بس، حتى
                            // ما ينعكس ترتيبه بسبب اتجاه الصفحة RTL
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '$value/30 ($completionPercent%)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // عرض ثابت لكل عمود (البار + مساحة الاسم تحته) حتى ما تلزق الأسماء ببعض
  // مهما طال اسم الطالبة أو كتر عدد الطالبات
  static const double _slotWidth = 78;

  Widget _buildChart() {
    final sortedStudents = List<dynamic>.from(_students);
    sortedStudents.sort((a, b) => b['number'].compareTo(a['number']));

    final colors = _chartColors;

    // العرض الكلي المطلوب للمخطط = عدد الطالبات × عرض العمود الواحد
    final double availableWidth =
        MediaQuery.of(context).size.width - (AppDimensions.paddingMedium * 2);
    final double neededWidth = sortedStudents.length * _slotWidth;
    final double chartWidth =
        neededWidth > availableWidth ? neededWidth : availableWidth;

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxParts() + 1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.withValues(alpha: 0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final student = sortedStudents[groupIndex.toInt()];
              return BarTooltipItem(
                '${student['name']}: ${student['number']} جزء',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // ✅ مساحة كافية لسطرين من النص حتى لو الاسم طويل
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedStudents.length) {
                  return const SizedBox.shrink();
                }
                final student = sortedStudents[index];
                return SideTitleWidget(
                  meta: meta,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      // ✅ كل اسم محصور بعرض ثابت (عرض العمود) فما بيقدر
                      // يتمدد على حساب اسم الطالبة يلي جنبه
                      width: _slotWidth - 8,
                      child: Text(
                        student['name'].toString(),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 1) return const Text('');
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 28,
              interval: 1,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xffe0e0e0)),
        ),
        barGroups: sortedStudents.asMap().entries.map((entry) {
          final index = entry.key;
          final student = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: student['number'].toDouble(),
                color: colors[index % colors.length],
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );

    // ✅ لو عدد الطالبات كبير، المخطط بينسحب أفقياً بدل ما يضغط الأعمدة
    // والأسماء على بعض. كل عمود إله مساحة ثابتة مضمونة (_slotWidth).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: chart,
      ),
    );
  }

  int _getMaxParts() {
    if (_students.isEmpty) return 0;
    int maxParts = 0;
    for (final student in _students) {
      if (student['number'] > maxParts) maxParts = student['number'];
    }
    return maxParts;
  }

  // ✅ قائمة "تفاصيل الحفظ" الجديدة: كل طالبة بكرت لحالها بدل صف جدول
  // - وسام ذهبي/فضي/برونزي لأول 3 طالبات
  // - أفاتار بنفس لون عمودها بالمخطط
  // - شريط تقدّم (عدد الأجزاء من 30) مع النسبة
  // - ضغطة عالكرت بتوديكي لتفاصيل الطالبة كاملة
  // - كل كرت بيدخل بأنيميشن (fade + انزلاق) بعد يلي قبله بفارق بسيط
  Widget _buildRankingList() {
    final sortedStudents = List<dynamic>.from(_students);
    sortedStudents.sort((a, b) => b['number'].compareTo(a['number']));

    return Column(
      children: sortedStudents.asMap().entries.map((entry) {
        final index = entry.key;
        final student = entry.value;
        final int number = (student['number'] as num).toInt();
        final double progress = (number / _kTotalParts).clamp(0, 1).toDouble();
        final int percent = (progress * 100).round();
        final Color color = _chartColors[index % _chartColors.length];
        final bool revealed = _revealedRanks.contains(index);

        return AnimatedOpacity(
          opacity: revealed ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: revealed ? Offset.zero : const Offset(0, 0.06),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusMedium),
              ),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusMedium),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.studentDetails,
                    arguments: Map<String, dynamic>.from(student),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _buildRankBadge(index),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color,
                        child: Text(
                          student['name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppDimensions.fontSizeMedium,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // ✅ Directionality.ltr حتى ما ينعكس ترتيب
                          // الرقمين بسبب اتجاه الصفحة العربي (RTL)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '$number/$_kTotalParts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$percent٪',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_left,
                          color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // وسام الترتيب: ذهبي/فضي/برونزي لأول 3، رقم عادي لباقي الطالبات
  Widget _buildRankBadge(int index) {
    const medalColors = [
      Color(0xFFFFD700), // ذهبي
      Color(0xFFC0C0C0), // فضي
      Color(0xFFCD7F32), // برونزي
    ];

    if (index < 3) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: medalColors[index],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.emoji_events, size: 15, color: Colors.white),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
