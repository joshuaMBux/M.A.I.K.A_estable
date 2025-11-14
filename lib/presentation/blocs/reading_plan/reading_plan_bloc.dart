import 'package:flutter_bloc/flutter_bloc.dart';
import 'reading_plan_event.dart';
import 'reading_plan_state.dart';
import '../../../domain/usecases/reading_plan/get_default_reading_plan_id_usecase.dart';
import '../../../domain/usecases/reading_plan/get_reading_plan_detail_usecase.dart';
import '../../../domain/usecases/reading_plan/toggle_reading_plan_day_usecase.dart';

class ReadingPlanBloc extends Bloc<ReadingPlanEvent, ReadingPlanState> {
  final GetDefaultReadingPlanIdUseCase getDefaultPlanIdUseCase;
  final GetReadingPlanDetailUseCase getReadingPlanDetailUseCase;
  final ToggleReadingPlanDayUseCase toggleReadingPlanDayUseCase;

  int? _activePlanId;

  ReadingPlanBloc({
    required this.getDefaultPlanIdUseCase,
    required this.getReadingPlanDetailUseCase,
    required this.toggleReadingPlanDayUseCase,
  }) : super(const ReadingPlanInitial()) {
    on<ReadingPlanStarted>(_onStarted);
    on<ReadingPlanDayToggled>(_onDayToggled);
  }

  Future<void> _onStarted(
    ReadingPlanStarted event,
    Emitter<ReadingPlanState> emit,
  ) async {
    emit(const ReadingPlanLoading());
    try {
      final requestedPlanId = event.planId ?? _activePlanId;
      final planId = requestedPlanId ?? await getDefaultPlanIdUseCase();

      if (planId == null) {
        emit(
          const ReadingPlanError(
            'No se encontro un plan de lectura disponible.',
          ),
        );
        return;
      }

      _activePlanId = planId;
      final plan = await getReadingPlanDetailUseCase(planId: planId);
      emit(ReadingPlanLoaded(plan: plan));
    } catch (error) {
      emit(
        ReadingPlanError(
          'No se pudo cargar el plan de lectura. ${error.toString()}',
        ),
      );
    }
  }

  Future<void> _onDayToggled(
    ReadingPlanDayToggled event,
    Emitter<ReadingPlanState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ReadingPlanLoaded || _activePlanId == null) {
      return;
    }

    emit(currentState.copyWith(isUpdating: true));

    try {
      await toggleReadingPlanDayUseCase(
        planId: _activePlanId!,
        day: event.day,
        completed: event.completed,
      );

      final updatedPlan = await getReadingPlanDetailUseCase(
        planId: _activePlanId!,
      );

      emit(ReadingPlanLoaded(plan: updatedPlan));
    } catch (error) {
      emit(
        ReadingPlanError(
          'No se pudo actualizar el progreso. ${error.toString()}',
        ),
      );
      emit(currentState.copyWith(isUpdating: false));
    }
  }
}
