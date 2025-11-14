import 'package:equatable/equatable.dart';
import '../../../domain/entities/devotional.dart';

abstract class DevotionalState extends Equatable {
  const DevotionalState();

  @override
  List<Object?> get props => [];
}

class DevotionalInitial extends DevotionalState {
  const DevotionalInitial();
}

class DevotionalLoading extends DevotionalState {
  const DevotionalLoading();
}

class DevotionalLoaded extends DevotionalState {
  final Devotional? today;
  final List<Devotional> recent;
  final Devotional? selected;
  final bool isRefreshing;

  const DevotionalLoaded({
    required this.today,
    required this.recent,
    this.selected,
    this.isRefreshing = false,
  });

  DevotionalLoaded copyWith({
    Devotional? today,
    List<Devotional>? recent,
    Devotional? selected,
    bool? isRefreshing,
  }) {
    return DevotionalLoaded(
      today: today ?? this.today,
      recent: recent ?? this.recent,
      selected: selected ?? this.selected,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [today, recent, selected, isRefreshing];
}

class DevotionalError extends DevotionalState {
  final String message;

  const DevotionalError(this.message);

  @override
  List<Object?> get props => [message];
}
