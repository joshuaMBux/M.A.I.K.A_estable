import 'package:equatable/equatable.dart';

abstract class DevotionalEvent extends Equatable {
  const DevotionalEvent();

  @override
  List<Object?> get props => [];
}

class DevotionalStarted extends DevotionalEvent {
  const DevotionalStarted();
}

class DevotionalRefreshed extends DevotionalEvent {
  const DevotionalRefreshed();
}

class DevotionalSelected extends DevotionalEvent {
  final int devotionalId;

  const DevotionalSelected(this.devotionalId);

  @override
  List<Object?> get props => [devotionalId];
}
