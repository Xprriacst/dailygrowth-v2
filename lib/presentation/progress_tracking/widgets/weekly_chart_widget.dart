import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class WeeklyChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> weeklyData;
  final Function(int) onDayTapped;

  const WeeklyChartWidget({
    Key? key,
    required this.weeklyData,
    required this.onDayTapped,
  }) : super(key: key);

  @override
  State<WeeklyChartWidget> createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends State<WeeklyChartWidget> {
  int selectedWeekIndex = 0;
  PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 35.h,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progression hebdomadaire',
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.onSurface)),
                    Row(children: [
                      GestureDetector(
                          onTap: () {
                            if (selectedWeekIndex > 0) {
                              setState(() {
                                selectedWeekIndex--;
                              });
                              _pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            }
                          },
                          child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                  color: selectedWeekIndex > 0
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme.lightTheme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppTheme
                                          .lightTheme.colorScheme.outline)),
                              child: CustomIconWidget(
                                  iconName: 'chevron_left',
                                  color: selectedWeekIndex > 0
                                      ? Colors.white
                                      : AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                  size: 4.w))),
                      SizedBox(width: 2.w),
                      GestureDetector(
                          onTap: () {
                            if (selectedWeekIndex <
                                widget.weeklyData.length - 1) {
                              setState(() {
                                selectedWeekIndex++;
                              });
                              _pageController.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            }
                          },
                          child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                  color: selectedWeekIndex <
                                          widget.weeklyData.length - 1
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme.lightTheme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppTheme
                                          .lightTheme.colorScheme.outline)),
                              child: CustomIconWidget(
                                  iconName: 'chevron_right',
                                  color: selectedWeekIndex <
                                          widget.weeklyData.length - 1
                                      ? Colors.white
                                      : AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                  size: 4.w))),
                    ]),
                  ])),
          Expanded(
              child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.weeklyData.length,
                  onPageChanged: (index) {
                    setState(() {
                      selectedWeekIndex = index;
                    });
                  },
                  itemBuilder: (context, weekIndex) {
                    final weekData = widget.weeklyData[weekIndex];
                    final days =
                        (weekData['days'] as List).cast<Map<String, dynamic>>();

                    return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: Offset(0, 2)),
                            ]),
                        child: Column(children: [
                          Text(weekData['weekRange'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.7))),
                          SizedBox(height: 2.h),
                          Expanded(
                              child: BarChart(BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 1.0,
                                  barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                          tooltipRoundedRadius: 8,
                                          getTooltipItem: (group, groupIndex,
                                              rod, rodIndex) {
                                            final day = days[group.x.toInt()];
                                            return BarTooltipItem(
                                                '${day['dayName']}\n${day['completed'] ? 'Complété' : 'Non complété'}',
                                                GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11.sp));
                                          }),
                                      touchCallback: (FlTouchEvent event,
                                          barTouchResponse) {
                                        if (event is FlTapUpEvent &&
                                            barTouchResponse?.spot != null) {
                                          final touchedIndex = barTouchResponse!
                                              .spot!.touchedBarGroupIndex;
                                          widget.onDayTapped(touchedIndex);
                                        }
                                      }),
                                  titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (double value,
                                                  TitleMeta meta) {
                                                final day = days[value.toInt()];
                                                return Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 1.h),
                                                    child: Text(
                                                        (day['dayName']
                                                                as String)
                                                            .substring(0, 1),
                                                        style: GoogleFonts.inter(
                                                            color: AppTheme
                                                                .lightTheme
                                                                .colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                    alpha: 0.6),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 11.sp)));
                                              }))),
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(show: false),
                                  barGroups: days.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final day = entry.value;
                                    final completed = day['completed'] as bool;

                                    return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                              toY: completed ? 1.0 : 0.3,
                                              color: completed
                                                  ? AppTheme.lightTheme
                                                      .colorScheme.primary
                                                  : AppTheme.lightTheme
                                                      .colorScheme.outline,
                                              width: 6.w,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                        ]);
                                  }).toList()))),
                        ]));
                  })),
        ]));
  }
}