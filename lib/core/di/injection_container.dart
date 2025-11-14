import 'package:get_it/get_it.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/verse_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/verse_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/chat/send_message_usecase.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(() => AuthBloc(loginUseCase: sl()));
  sl.registerFactory(() => ChatBloc(sendMessageUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
  sl.registerLazySingleton<VerseRepository>(() => VerseRepositoryImpl());
}
