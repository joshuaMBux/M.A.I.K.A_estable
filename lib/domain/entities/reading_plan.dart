import 'package:equatable/equatable.dart';
import 'reading_plan_day.dart';

class ReadingPlan extends Equatable {
  final int id;
  final String name;
  final String? description;
  final List<ReadingPlanDay> days;

  const ReadingPlan({
    required this.id,
    required this.name,
    this.description,
    required this.days,
  });

  int get totalDays => days.length;

  int get completedDays => days.where((day) => day.completed).length;

  double get progress => totalDays == 0 ? 0 : completedDays / totalDays;

  ReadingPlan copyWith({List<ReadingPlanDay>? days}) {
    return ReadingPlan(
      id: id,
      name: name,
      description: description,
      days: days ?? this.days,
    );
  }

  @override
  List<Object?> get props => [id, name, description, days];
}
