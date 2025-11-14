import 'package:equatable/equatable.dart';

abstract class ReadingPlanEvent extends Equatable {
  const ReadingPlanEvent();

  @override
  List<Object?> get props => [];
}

class ReadingPlanStarted extends ReadingPlanEvent {
  final int? planId;

  const ReadingPlanStarted({this.planId});

  @override
  List<Object?> get props => [planId];
}

class ReadingPlanDayToggled extends ReadingPlanEvent {
  final int day;
  final bool completed;

  const ReadingPlanDayToggled({required this.day, required this.completed});

  @override
  List<Object?> get props => [day, completed];
}
