import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/chat_local_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/verse_repository_impl.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/repositories/versiculo_repository.dart';
import '../../data/repositories/reading_plan_repository_impl.dart';
import '../../data/repositories/devotional_repository_impl.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../data/repositories/favorito_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/verse_repository.dart';
import '../../domain/repositories/reading_plan_repository.dart';
import '../../domain/repositories/devotional_repository.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/chat/load_chat_session_usecase.dart';
import '../../domain/usecases/chat/send_message_usecase.dart';
import '../../domain/usecases/chat/sync_pending_messages_usecase.dart';
import '../../domain/usecases/chat/toggle_favorite_message_usecase.dart';
import '../../domain/usecases/reading_plan/get_default_reading_plan_id_usecase.dart';
import '../../domain/usecases/reading_plan/get_reading_plan_detail_usecase.dart';
import '../../domain/usecases/reading_plan/toggle_reading_plan_day_usecase.dart';
import '../../domain/usecases/devotional/get_today_devotional_usecase.dart';
import '../../domain/usecases/devotional/get_recent_devotionals_usecase.dart';
import '../../domain/usecases/devotional/get_devotional_by_id_usecase.dart';
import '../../domain/usecases/note/add_note_usecase.dart';
import '../../domain/usecases/note/get_notes_for_verse_usecase.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/reading_plan/reading_plan_bloc.dart';
import '../../presentation/blocs/devotional/devotional_bloc.dart';
import '../../presentation/blocs/theme/theme_cubit.dart';
import '../../presentation/blocs/audio_bible/audio_bible_bloc.dart';
import '../../core/services/audio_sync_service.dart';
import '../../core/services/audio_download_service.dart';
import '../../core/services/audio_player_manager.dart';
import '../../data/repositories/audio_bible_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core - Solo inicializar base de datos en plataformas móviles/desktop
  DatabaseHelper? databaseHelper;
  if (!kIsWeb) {
    databaseHelper = DatabaseHelper();
    await databaseHelper.database;
    sl.registerLazySingleton<DatabaseHelper>(() => databaseHelper!);
  }

  sl.registerLazySingleton<ChatLocalDataSource>(
    () => createChatLocalDataSource(databaseHelper),
  );

  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Audio services
  // Always register the player manager (works on all platforms, including web)
  sl.registerLazySingleton(() => AudioPlayerManager());

  // Register DB-backed services only on non-web targets
  if (!kIsWeb) {
    sl.registerLazySingleton(() => AudioSyncService(databaseHelper!));
    sl.registerLazySingleton(() => AudioDownloadService(databaseHelper!));
  }

  // Repository supports web fallbacks internally; inject services when available
  sl.registerLazySingleton(() => AudioBibleRepository(
    dbHelper: databaseHelper,
    syncService: !kIsWeb ? sl<AudioSyncService>() : null,
    downloadService: !kIsWeb ? sl<AudioDownloadService>() : null,
  ));

  // BLoC depends on repository and player manager; safe for all platforms
  sl.registerFactory(() => AudioBibleBloc(
    repository: sl<AudioBibleRepository>(),
    playerManager: sl<AudioPlayerManager>(),
  ));

  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerFactory(
    () => ChatBloc(
      loadChatSessionUseCase: sl(),
      sendChatMessageUseCase: sl(),
      syncPendingMessagesUseCase: sl(),
      toggleFavoriteMessageUseCase: sl(),
      chatRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => ReadingPlanBloc(
      getDefaultPlanIdUseCase: sl(),
      getReadingPlanDetailUseCase: sl(),
      toggleReadingPlanDayUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => DevotionalBloc(
      getTodayDevotionalUseCase: sl(),
      getRecentDevotionalsUseCase: sl(),
      getDevotionalByIdUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => ThemeCubit());

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LoadChatSessionUseCase(sl()));
  sl.registerLazySingleton(() => SendChatMessageUseCase(sl()));
  sl.registerLazySingleton(() => SyncPendingMessagesUseCase(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteMessageUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      localDataSource: sl<ChatLocalDataSource>(),
      apiClient: sl<ApiClient>(),
    ),
  );
  sl.registerLazySingleton<VerseRepository>(() => VerseRepositoryImpl());
  sl.registerLazySingleton<ReadingPlanRepository>(
    () => ReadingPlanRepositoryImpl(),
  );
  sl.registerLazySingleton<DevotionalRepository>(
    () => DevotionalRepositoryImpl(),
  );
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(kIsWeb ? null : sl<DatabaseHelper>()),
  );

  // Database repositories (only for non-web platforms)
  if (!kIsWeb) {
    sl.registerLazySingleton(() => UsuarioRepository());
    sl.registerLazySingleton(() => VersiculoRepository());
    sl.registerLazySingleton(() => FavoritoRepository());
  }

  // Reading plan use cases
  sl.registerLazySingleton(() => GetDefaultReadingPlanIdUseCase(sl()));
  sl.registerLazySingleton(() => GetReadingPlanDetailUseCase(sl()));
  sl.registerLazySingleton(() => ToggleReadingPlanDayUseCase(sl()));
  sl.registerLazySingleton(() => GetTodayDevotionalUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentDevotionalsUseCase(sl()));
  sl.registerLazySingleton(() => GetDevotionalByIdUseCase(sl()));
  sl.registerLazySingleton(() => AddNoteUseCase(sl()));
  sl.registerLazySingleton(() => GetNotesForVerseUseCase(sl()));
}
