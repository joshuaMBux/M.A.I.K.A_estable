import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../blocs/reading_plan/reading_plan_bloc.dart';
import '../../blocs/reading_plan/reading_plan_event.dart';
import '../../blocs/reading_plan/reading_plan_state.dart';
import '../../../domain/entities/reading_plan.dart';
import '../../../domain/entities/reading_plan_day.dart';

class ReadingPlanScreen extends StatelessWidget {
  const ReadingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ReadingPlanBloc>()..add(const ReadingPlanStarted()),
      child: const _ReadingPlanView(),
    );
  }
}

class _ReadingPlanView extends StatelessWidget {
  const _ReadingPlanView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Plan de Lectura'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<ReadingPlanBloc, ReadingPlanState>(
        listener: (context, state) {
          if (state is ReadingPlanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReadingPlanLoading || state is ReadingPlanInitial) {
            return const _ReadingPlanLoading();
          } else if (state is ReadingPlanLoaded) {
            return _ReadingPlanContent(
              plan: state.plan,
              isUpdating: state.isUpdating,
            );
          } else if (state is ReadingPlanError) {
            return _ReadingPlanErrorView(error: state.message);
          }
          return const _ReadingPlanLoading();
        },
      ),
    );
  }
}

class _ReadingPlanLoading extends StatelessWidget {
  const _ReadingPlanLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
    );
  }
}

class _ReadingPlanErrorView extends StatelessWidget {
  final String error;

  const _ReadingPlanErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el plan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ReadingPlanBloc>().add(const ReadingPlanStarted());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingPlanContent extends StatelessWidget {
  final ReadingPlan plan;
  final bool isUpdating;

  const _ReadingPlanContent({required this.plan, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final progressPercent = (plan.progress * 100).round();
    final completedLabel =
        '${plan.completedDays}/${plan.totalDays} dias completados';

    final children = <Widget>[
      _PlanSummaryCard(
        plan: plan,
        progressPercent: progressPercent,
        completedLabel: completedLabel,
        isUpdating: isUpdating,
      ),
      const SizedBox(height: 24),
      Text(
        'Lecturas diarias',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      ...plan.days.map(
        (day) => _ReadingPlanDayTile(day: day, isUpdating: isUpdating),
      ),
      if (plan.days.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Text(
            'Todavia no hay lecturas asignadas para este plan.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      const SizedBox(height: 16),
    ];

    return RefreshIndicator(
      color: const Color(0xFF6B46C1),
      onRefresh: () async {
        context.read<ReadingPlanBloc>().add(
          ReadingPlanStarted(planId: plan.id),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: children,
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  final ReadingPlan plan;
  final int progressPercent;
  final String completedLabel;
  final bool isUpdating;

  const _PlanSummaryCard({
    required this.plan,
    required this.progressPercent,
    required this.completedLabel,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.description ??
                          'Acompanate de Maika mientras avanzas dia a dia.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.totalDays} dias',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: plan.progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFCF99),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                completedLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (isUpdating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadingPlanDayTile extends StatelessWidget {
  final ReadingPlanDay day;
  final bool isUpdating;

  const _ReadingPlanDayTile({required this.day, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReadingPlanBloc>();
    final isCompleted = day.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isCompleted ? 0.35 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFF6B46C1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFF6B46C1).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                day.day.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6B46C1),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        day.reference,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Hecho',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (day.comment != null && day.comment!.isNotEmpty)
                  Text(
                    day.comment!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Checkbox(
            value: isCompleted,
            onChanged: isUpdating
                ? null
                : (value) {
                    bloc.add(
                      ReadingPlanDayToggled(
                        day: day.day,
                        completed: value ?? false,
                      ),
                    );
                  },
            activeColor: const Color(0xFF10B981),
            side: const BorderSide(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
