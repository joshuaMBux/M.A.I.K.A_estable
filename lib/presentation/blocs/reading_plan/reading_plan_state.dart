import 'package:equatable/equatable.dart';
import '../../../domain/entities/reading_plan.dart';

abstract class ReadingPlanState extends Equatable {
  const ReadingPlanState();

  @override
  List<Object?> get props => [];
}

class ReadingPlanInitial extends ReadingPlanState {
  const ReadingPlanInitial();
}

class ReadingPlanLoading extends ReadingPlanState {
  const ReadingPlanLoading();
}

class ReadingPlanLoaded extends ReadingPlanState {
  final ReadingPlan plan;
  final bool isUpdating;

  const ReadingPlanLoaded({required this.plan, this.isUpdating = false});

  ReadingPlanLoaded copyWith({ReadingPlan? plan, bool? isUpdating}) {
    return ReadingPlanLoaded(
      plan: plan ?? this.plan,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [plan, isUpdating];
}

class ReadingPlanError extends ReadingPlanState {
  final String message;

  const ReadingPlanError(this.message);

  @override
  List<Object?> get props => [message];
}
