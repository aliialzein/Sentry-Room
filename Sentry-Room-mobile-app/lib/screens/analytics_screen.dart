import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/analytics_action.dart';
import '../../models/analytics_summary.dart';
import '../../models/analytics_trend.dart';
import '../../models/analytics_type.dart';
import '../../models/ai_summary.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_report_service.dart';
import '../../services/report_service.dart';
import 'emergency/providers/emergency_incident_log_provider.dart';
import 'home/widgets/home_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AiReportService _aiReportService = AiReportService();
  final ReportService _reportService = ReportService();
  AiSummary? _aiSummary;
  bool _isAiLoading = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialAnalytics();
    });
  }

  Future<void> _loadInitialAnalytics() async {
    await _loadAnalytics();
    if (!mounted) return;
    await _loadAiSummary(context.read<AnalyticsProvider>().selectedRange);
  }

  Future<void> _loadAnalytics() async {
    final authToken = context.read<AuthProvider>().token;
    await context.read<AnalyticsProvider>().loadAnalytics(
          authToken: authToken,
        );
  }

  Future<void> _changeRange(AnalyticsRange range) async {
    final authToken = context.read<AuthProvider>().token;
    await context.read<AnalyticsProvider>().changeRange(
          range,
          authToken: authToken,
        );
    if (!mounted) return;
    await _loadAiSummary(range);
  }

  Future<void> _loadAiSummary(AnalyticsRange range) async {
    final authToken = context.read<AuthProvider>().token;

    if (authToken == null || authToken.isEmpty) {
      setState(() {
        _aiSummary = null;
        _aiError = 'Sign in again to load AI summaries.';
      });
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiError = null;
    });

    try {
      final summary = await _aiReportService.loadAiSummary(
        range: range.apiValue,
        authToken: authToken,
      );
      if (!mounted) return;
      setState(() {
        _aiSummary = summary;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _aiError = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  Future<void> _showExportReportDialog() async {
    var selectedRange = context.read<AnalyticsProvider>().selectedRange;
    final range = await showDialog<AnalyticsRange>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Export Report'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Range',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final range in AnalyticsRange.values)
                        ChoiceChip(
                          label: Text(range.label),
                          selected: selectedRange == range,
                          showCheckmark: false,
                          avatar: selectedRange == range
                              ? const Icon(Icons.check_rounded, size: 16)
                              : null,
                          onSelected: (_) {
                            setDialogState(() => selectedRange = range);
                          },
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(selectedRange),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Generate PDF'),
                ),
              ],
            );
          },
        );
      },
    );

    if (range != null) {
      await _generateReport(range);
    }
  }

  Future<void> _generateReport(AnalyticsRange range) async {
    final authToken = context.read<AuthProvider>().token;
    final messenger = ScaffoldMessenger.of(context);

    if (authToken == null || authToken.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sign in again to export analytics reports.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showGeneratingDialog();

    try {
      final report = await _reportService.generatePdfReport(
        range: range.apiValue,
        authToken: authToken,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final action = await _showReportActions(report);
      if (action == null) return;
      await _runReportAction(action, report);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          backgroundColor: HomeColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showGeneratingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 14),
              Expanded(child: Text('Generating PDF report...')),
            ],
          ),
        );
      },
    );
  }

  Future<_ReportAction?> _showReportActions(PdfReportFile report) {
    return showModalBottomSheet<_ReportAction>(
      context: context,
      backgroundColor: HomeColors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  report.filename,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _ReportActionTile(
                  icon: Icons.visibility_rounded,
                  color: HomeColors.accent,
                  title: 'Preview',
                  onTap: () => Navigator.of(context).pop(_ReportAction.preview),
                ),
                _ReportActionTile(
                  icon: Icons.ios_share_rounded,
                  color: HomeColors.success,
                  title: 'Share',
                  onTap: () => Navigator.of(context).pop(_ReportAction.share),
                ),
                _ReportActionTile(
                  icon: Icons.download_rounded,
                  color: HomeColors.warning,
                  title: 'Download',
                  onTap: () => Navigator.of(context).pop(_ReportAction.download),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runReportAction(
    _ReportAction action,
    PdfReportFile report,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case _ReportAction.preview:
          await _reportService.previewPdfReport(report);
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text('PDF report opened.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        case _ReportAction.share:
          await _reportService.sharePdfReport(report);
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text('PDF report ready to share.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        case _ReportAction.download:
          final path = await _reportService.downloadPdfReport(report);
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('PDF report saved to $path'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          backgroundColor: HomeColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Consumer2<AnalyticsProvider, EmergencyIncidentLogProvider>(
          builder: (context, analytics, incidentLogs, _) {
            final localPendingSync = incidentLogs.logs
                .where((incident) => !incident.isSynced)
                .length;

            return RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: HomeColors.background,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    leading: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: const Text(
                      'Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Refresh analytics',
                        icon: analytics.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                color: Colors.white,
                              ),
                        onPressed: analytics.isLoading ? null : _loadAnalytics,
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _buildContent(
                              analytics,
                              localPendingSync,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    AnalyticsProvider analytics,
    int localPendingSync,
  ) {
    if (analytics.isLoading && !analytics.hasAnalyticsData) {
      return const LoadingStrip(
        key: ValueKey('analytics-loading'),
        label: 'Loading analytics...',
      );
    }

    if (analytics.errorMessage != null && !analytics.hasAnalyticsData) {
      return _AnalyticsErrorState(
        key: const ValueKey('analytics-error'),
        message: analytics.errorMessage!,
        onRetry: _loadAnalytics,
      );
    }

    return Column(
      key: const ValueKey('analytics-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardHeader(
          selectedRange: analytics.selectedRange,
          onRangeChanged: _changeRange,
          onExportReport: _showExportReportDialog,
        ),
        if (analytics.errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineError(message: analytics.errorMessage!),
        ],
        const SizedBox(height: 16),
        _KpiGrid(
          summary: analytics.summary.copyWith(
            pendingSync: localPendingSync,
          ),
        ),
        const SizedBox(height: 18),
        _AiSummaryCard(
          summary: _aiSummary,
          isLoading: _isAiLoading,
          errorMessage: _aiError,
          onRefresh: () => _loadAiSummary(analytics.selectedRange),
        ),
        const SizedBox(height: 18),
        _TrendSection(trends: analytics.trends),
        const SizedBox(height: 18),
        _BreakdownGrid(
          types: analytics.types,
          actions: analytics.actions,
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.selectedRange,
    required this.onRangeChanged,
    required this.onExportReport,
  });

  final AnalyticsRange selectedRange;
  final ValueChanged<AnalyticsRange> onRangeChanged;
  final VoidCallback onExportReport;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final title = Row(
            children: [
              const IconBubble(
                icon: Icons.analytics_rounded,
                color: HomeColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Analytics',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Incident volume, outcomes, and response channels',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final filters = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final range in AnalyticsRange.values)
                ChoiceChip(
                  label: Text(range.label),
                  selected: selectedRange == range,
                  showCheckmark: false,
                  avatar: selectedRange == range
                      ? const Icon(Icons.check_rounded, size: 16)
                      : null,
                  selectedColor: HomeColors.accent.withValues(alpha: 0.2),
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  side: BorderSide(
                    color: selectedRange == range
                        ? HomeColors.accent.withValues(alpha: 0.45)
                        : Colors.white12,
                  ),
                  labelStyle: TextStyle(
                    color:
                        selectedRange == range ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => onRangeChanged(range),
                ),
              FilledButton.tonalIcon(
                onPressed: onExportReport,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Export Report'),
                style: FilledButton.styleFrom(
                  foregroundColor: HomeColors.accent,
                  backgroundColor: HomeColors.accent.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                filters,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              filters,
            ],
          );
        },
      ),
    );
  }
}

enum _ReportAction {
  preview,
  share,
  download,
}

class _ReportActionTile extends StatelessWidget {
  const _ReportActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconBubble(icon: icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({
    required this.summary,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  });

  final AiSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.auto_awesome_rounded,
                color: HomeColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Executive AI Summary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary == null
                          ? 'Aggregated management insight'
                          : 'Generated ${DateFormat('MMM d, HH:mm').format(summary!.generatedAt.toLocal())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh AI summary',
                onPressed: isLoading ? null : onRefresh,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && summary == null) {
      return const LoadingStrip(
        key: ValueKey('ai-loading'),
        label: 'Generating management summary...',
      );
    }

    if (errorMessage != null && summary == null) {
      return _InlineError(
        key: const ValueKey('ai-error'),
        message: errorMessage!,
      );
    }

    final currentSummary = summary;
    if (currentSummary == null) {
      return const _ChartEmptyState(
        key: ValueKey('ai-empty'),
        icon: Icons.auto_awesome_outlined,
        label: 'AI summary has not been generated yet',
      );
    }

    return Column(
      key: const ValueKey('ai-content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentSummary.summary,
          style: const TextStyle(
            color: Colors.white70,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (currentSummary.keyFindings.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _AiListSection(
            title: 'Key Findings',
            icon: Icons.insights_rounded,
          ),
          for (final finding in currentSummary.keyFindings)
            _AiListRow(text: finding),
        ],
        if (currentSummary.recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _AiListSection(
            title: 'Recommendations',
            icon: Icons.task_alt_rounded,
          ),
          for (final recommendation in currentSummary.recommendations)
            _AiListRow(text: recommendation),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineError(message: errorMessage!),
        ],
      ],
    );
  }
}

class _AiListSection extends StatelessWidget {
  const _AiListSection({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HomeColors.accent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AiListRow extends StatelessWidget {
  const _AiListRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: HomeColors.accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 620
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 2.7 : 1.9,
          children: [
            _KpiCard(
              label: 'Total Incidents',
              value: summary.totalIncidents,
              icon: Icons.report_rounded,
              color: HomeColors.accent,
              helper: summary.mostCommonType ?? 'No dominant type',
            ),
            _KpiCard(
              label: 'Pending Sync',
              value: summary.pendingSync,
              icon: Icons.cloud_sync_rounded,
              color: HomeColors.warning,
              helper: 'Awaiting completion',
            ),
            _KpiCard(
              label: 'Successful Actions',
              value: summary.successfulActions,
              icon: Icons.check_circle_rounded,
              color: HomeColors.success,
              helper: 'Completed or shared',
            ),
            _KpiCard(
              label: 'Failed Actions',
              value: summary.failedActions,
              icon: Icons.error_rounded,
              color: HomeColors.danger,
              helper: 'Requires review',
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.helper,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: value.toDouble()),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        animatedValue.round().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.trends});

  final List<AnalyticsTrend> trends;

  @override
  Widget build(BuildContext context) {
    return _ChartPanel(
      title: 'Incident Trend',
      subtitle: 'Emergency reports over time',
      child: SizedBox(
        height: 280,
        child: _TrendLineChart(trends: trends),
      ),
    );
  }
}

class _BreakdownGrid extends StatelessWidget {
  const _BreakdownGrid({
    required this.types,
    required this.actions,
  });

  final List<AnalyticsType> types;
  final List<AnalyticsAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final byType = _ChartPanel(
          title: 'Incidents By Type',
          subtitle: 'Distribution by emergency category',
          child: SizedBox(
            height: 300,
            child: _TypePieChart(types: types),
          ),
        );
        final byAction = _ChartPanel(
          title: 'Actions Used',
          subtitle: 'Call, SMS, email, and share activity',
          child: SizedBox(
            height: 300,
            child: _ActionBarChart(actions: actions),
          ),
        );

        if (!wide) {
          return Column(
            children: [
              byType,
              const SizedBox(height: 18),
              byAction,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: byType),
            const SizedBox(width: 18),
            Expanded(child: byAction),
          ],
        );
      },
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({required this.trends});

  final List<AnalyticsTrend> trends;

  @override
  Widget build(BuildContext context) {
    final visibleTrends = trends.where((trend) => trend.count >= 0).toList();
    final total = visibleTrends.fold<int>(
      0,
      (sum, trend) => sum + trend.count,
    );

    if (visibleTrends.isEmpty || total == 0) {
      return const _ChartEmptyState(
        icon: Icons.show_chart_rounded,
        label: 'No trend data for this range',
      );
    }

    final maxCount = visibleTrends
        .map((trend) => trend.count)
        .fold<int>(0, math.max)
        .toDouble();
    final spots = <FlSpot>[
      for (var index = 0; index < visibleTrends.length; index++)
        FlSpot(index.toDouble(), visibleTrends[index].count.toDouble()),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (visibleTrends.length - 1).toDouble(),
        minY: 0,
        maxY: math.max(1, maxCount + 1),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _axisInterval(maxCount),
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.08),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: _axisInterval(maxCount),
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _bottomInterval(visibleTrends.length),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= visibleTrends.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    DateFormat('MMM d').format(visibleTrends[index].date),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => HomeColors.surface,
            getTooltipItems: (spots) {
              return [
                for (final spot in spots)
                  LineTooltipItem(
                    '${DateFormat('MMM d').format(visibleTrends[spot.x.toInt()].date)}\n${spot.y.toInt()} incidents',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ];
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: HomeColors.accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: visibleTrends.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: HomeColors.accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePieChart extends StatelessWidget {
  const _TypePieChart({required this.types});

  final List<AnalyticsType> types;

  @override
  Widget build(BuildContext context) {
    final visibleTypes = types.where((item) => item.count > 0).toList();
    final total = visibleTypes.fold<int>(0, (sum, item) => sum + item.count);

    if (visibleTypes.isEmpty || total == 0) {
      return const _ChartEmptyState(
        icon: Icons.pie_chart_rounded,
        label: 'No type data for this range',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return compact
            ? Column(
                children: [
                  Expanded(child: _buildChart(visibleTypes, total)),
                  const SizedBox(height: 12),
                  _Legend(items: _legendItems(visibleTypes)),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildChart(visibleTypes, total)),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 170,
                    child: _Legend(items: _legendItems(visibleTypes)),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildChart(List<AnalyticsType> visibleTypes, int total) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 42,
        sectionsSpace: 2,
        sections: [
          for (var index = 0; index < visibleTypes.length; index++)
            PieChartSectionData(
              value: visibleTypes[index].count.toDouble(),
              title:
                  '${((visibleTypes[index].count / total) * 100).round()}%',
              radius: 70,
              color: _chartColors[index % _chartColors.length],
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  List<_LegendItem> _legendItems(List<AnalyticsType> visibleTypes) {
    return [
      for (var index = 0; index < visibleTypes.length; index++)
        _LegendItem(
          label: visibleTypes[index].type,
          value: visibleTypes[index].count.toString(),
          color: _chartColors[index % _chartColors.length],
        ),
    ];
  }
}

class _ActionBarChart extends StatelessWidget {
  const _ActionBarChart({required this.actions});

  final List<AnalyticsAction> actions;

  @override
  Widget build(BuildContext context) {
    final total = actions.fold<int>(0, (sum, action) => sum + action.count);

    if (actions.isEmpty || total == 0) {
      return const _ChartEmptyState(
        icon: Icons.bar_chart_rounded,
        label: 'No action data for this range',
      );
    }

    final maxCount = actions
        .map((action) => action.count)
        .fold<int>(0, math.max)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: math.max(1, maxCount + 1),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _axisInterval(maxCount),
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.08),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _axisInterval(maxCount),
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= actions.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    actions[index].action,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => HomeColors.surface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${actions[group.x].action}\n${rod.toY.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var index = 0; index < actions.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: actions[index].count.toDouble(),
                  color: _chartColors[index % _chartColors.length],
                  width: 24,
                  borderRadius: BorderRadius.circular(7),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LegendItem {
  final String label;
  final String value;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: HomeColors.accent, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  const _AnalyticsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(
            icon: Icons.error_outline_rounded,
            color: HomeColors.danger,
          ),
          const SizedBox(height: 14),
          const Text(
            'Analytics unavailable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white60,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: HomeColors.danger.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: HomeColors.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _axisInterval(double maxValue) {
  if (maxValue <= 4) return 1;
  if (maxValue <= 12) return 2;
  if (maxValue <= 30) return 5;
  return 10;
}

double _bottomInterval(int itemCount) {
  if (itemCount <= 7) return 1;
  if (itemCount <= 14) return 2;
  return 5;
}

const _chartColors = [
  HomeColors.accent,
  HomeColors.success,
  HomeColors.warning,
  HomeColors.danger,
  Color(0xFFA78BFA),
  Color(0xFF22D3EE),
];
