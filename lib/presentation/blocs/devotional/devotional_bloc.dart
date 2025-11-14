import 'package:flutter_bloc/flutter_bloc.dart';
import 'devotional_event.dart';
import 'devotional_state.dart';
import '../../../domain/usecases/devotional/get_devotional_by_id_usecase.dart';
import '../../../domain/usecases/devotional/get_recent_devotionals_usecase.dart';
import '../../../domain/usecases/devotional/get_today_devotional_usecase.dart';
import '../../../domain/entities/devotional.dart';

class DevotionalBloc extends Bloc<DevotionalEvent, DevotionalState> {
  final GetTodayDevotionalUseCase getTodayDevotionalUseCase;
  final GetRecentDevotionalsUseCase getRecentDevotionalsUseCase;
  final GetDevotionalByIdUseCase getDevotionalByIdUseCase;

  DevotionalBloc({
    required this.getTodayDevotionalUseCase,
    required this.getRecentDevotionalsUseCase,
    required this.getDevotionalByIdUseCase,
  }) : super(const DevotionalInitial()) {
    on<DevotionalStarted>(_onStarted);
    on<DevotionalRefreshed>(_onRefreshed);
    on<DevotionalSelected>(_onSelected);
  }

  Future<void> _onStarted(
    DevotionalStarted event,
    Emitter<DevotionalState> emit,
  ) async {
    emit(const DevotionalLoading());
    await _loadDevotionals(emit);
  }

  Future<void> _onRefreshed(
    DevotionalRefreshed event,
    Emitter<DevotionalState> emit,
  ) async {
    final currentState = state;
    if (currentState is DevotionalLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }
    await _loadDevotionals(emit, keepSelection: true);
  }

  Future<void> _onSelected(
    DevotionalSelected event,
    Emitter<DevotionalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DevotionalLoaded) {
      return;
    }

    final candidates = [
      if (currentState.today != null) currentState.today!,
      ...currentState.recent,
    ];

    Devotional? existing;
    for (final candidate in candidates) {
      if (candidate.id == event.devotionalId) {
        existing = candidate;
        break;
      }
    }

    if (existing == null) {
      final fetched = await getDevotionalByIdUseCase(event.devotionalId);
      if (fetched != null) {
        emit(currentState.copyWith(selected: fetched));
      }
    } else {
      emit(currentState.copyWith(selected: existing));
    }
  }

  Future<void> _loadDevotionals(
    Emitter<DevotionalState> emit, {
    bool keepSelection = false,
  }) async {
    try {
      final today = await getTodayDevotionalUseCase();
      final recent = await getRecentDevotionalsUseCase(limit: 14);

      final normalizedRecent = _normalizeList(today, recent);
      Devotional? selected;

      if (keepSelection && state is DevotionalLoaded) {
        final previous = (state as DevotionalLoaded).selected;
        if (previous != null) {
          for (final devotional in normalizedRecent) {
            if (devotional.id == previous.id) {
              selected = devotional;
              break;
            }
          }
          selected ??= today != null && today.id == previous.id ? today : null;
        }
      }

      emit(
        DevotionalLoaded(
          today: today,
          recent: normalizedRecent,
          selected: selected ?? today,
        ),
      );
    } catch (error) {
      emit(
        DevotionalError(
          'No se pudo cargar los devocionales. ${error.toString()}',
        ),
      );
    }
  }

  List<Devotional> _normalizeList(Devotional? today, List<Devotional> recent) {
    final seen = <int>{};
    final items = <Devotional>[];

    void addIfValid(Devotional? devotional) {
      if (devotional == null || seen.contains(devotional.id)) {
        return;
      }
      seen.add(devotional.id);
      items.add(devotional);
    }

    addIfValid(today);
    for (final devotional in recent) {
      addIfValid(devotional);
    }

    return items;
  }
}
