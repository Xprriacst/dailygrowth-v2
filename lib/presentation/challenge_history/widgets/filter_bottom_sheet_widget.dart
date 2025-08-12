import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final String selectedDomain;
  final String selectedStatus;
  final DateTimeRange? selectedDateRange;
  final Function(String domain, String status, DateTimeRange? dateRange)
      onApplyFilters;

  const FilterBottomSheetWidget({
    Key? key,
    required this.selectedDomain,
    required this.selectedStatus,
    this.selectedDateRange,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late String _selectedDomain;
  late String _selectedStatus;
  DateTimeRange? _selectedDateRange;

  final List<String> _domains = [
    'Tous',
    'Santé',
    'Relations',
    'Carrière',
    'Créativité',
    'Finances',
    'Spiritualité',
  ];

  final List<String> _statuses = [
    'Tous',
    'Terminé',
    'Ignoré',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDomain = widget.selectedDomain;
    _selectedStatus = widget.selectedStatus;
    _selectedDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtres',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDomain = 'Tous';
                      _selectedStatus = 'Tous';
                      _selectedDateRange = null;
                    });
                  },
                  child: Text(
                    'Réinitialiser',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Domain filter
                  _buildSectionTitle('Domaine de vie'),
                  SizedBox(height: 2.h),
                  _buildDomainChips(),

                  SizedBox(height: 4.h),

                  // Status filter
                  _buildSectionTitle('Statut'),
                  SizedBox(height: 2.h),
                  _buildStatusChips(),

                  SizedBox(height: 4.h),

                  // Date range filter
                  _buildSectionTitle('Période'),
                  SizedBox(height: 2.h),
                  _buildDateRangeSelector(),

                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(
                      _selectedDomain, _selectedStatus, _selectedDateRange);
                  Navigator.pop(context);
                },
                child: Text('Appliquer les filtres'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildDomainChips() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _domains.map((domain) {
        final isSelected = _selectedDomain == domain;
        return GestureDetector(
          onTap: () => setState(() => _selectedDomain = domain),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              domain,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _statuses.map((status) {
        final isSelected = _selectedStatus == status;
        return GestureDetector(
          onTap: () => setState(() => _selectedStatus = status),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    return GestureDetector(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024, 1, 1),
          lastDate: DateTime.now(),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppTheme.lightTheme.colorScheme.primary,
                    ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDateRange = picked);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'date_range',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                    : 'Sélectionner une période',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _selectedDateRange != null
                          ? AppTheme.lightTheme.colorScheme.onSurface
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                    ),
              ),
            ),
            if (_selectedDateRange != null)
              GestureDetector(
                onTap: () => setState(() => _selectedDateRange = null),
                child: CustomIconWidget(
                  iconName: 'clear',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
