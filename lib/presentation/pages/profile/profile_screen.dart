import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/gamification_models.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/settings/settings_cubit.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/auth_screen.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<GamificationDashboard>? _gamificationSubscription;
  GamificationDashboard? _gamificationDashboard;
  _SessionProfileData _session = const _SessionProfileData();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _gamificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final authState = context.read<AuthBloc>().state;
    var userId = 0;
    var userName = 'Usuario';
    var userEmail = 'Sin correo disponible';

    if (authState is AuthSuccess) {
      userId = int.tryParse(authState.user.id) ?? 0;
      userName = authState.user.name;
      userEmail = authState.user.email;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('user_id') ?? 0;
      final rawUser = prefs.getString('user_data');
      if (rawUser != null && rawUser.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawUser) as Map<String, dynamic>;
          userName = (decoded['name'] as String?)?.trim().isNotEmpty == true
              ? decoded['name'] as String
              : userName;
          userEmail = (decoded['email'] as String?)?.trim().isNotEmpty == true
              ? decoded['email'] as String
              : userEmail;
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _session = _SessionProfileData(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );
    });

    if (userId > 0 && di.sl.isRegistered<GamificationRepository>()) {
      await _bindGamification(userId);
    }
  }

  Future<void> _bindGamification(int userId) async {
    await _gamificationSubscription?.cancel();
    _gamificationSubscription = di
        .sl<GamificationRepository>()
        .watchDashboard(userId)
        .listen((dashboard) {
      if (!mounted) return;
      setState(() => _gamificationDashboard = dashboard);
    });
  }

  Future<String> _persistPickedImage(
    XFile picked, {
    required String prefix,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.name.isNotEmpty ? picked.name : picked.path);
    final fileName =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}${ext.isNotEmpty ? ext : '.jpg'}';
    final target = File(p.join(appDir.path, 'profile', fileName));

    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }

    final bytes = await picked.readAsBytes();
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return;
    final savedPath = await _persistPickedImage(picked, prefix: 'avatar');
    if (!context.mounted) return;
    context.read<SettingsCubit>().setProfileImagePath(savedPath);
  }

  void _showAvatarSheetFixed(BuildContext context) {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(rootContext, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de galeria'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(rootContext, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar foto'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  rootContext.read<SettingsCubit>().setProfileImagePath(null);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickBackgroundImage(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return;
    final savedPath = await _persistPickedImage(picked, prefix: 'bg');
    if (!context.mounted) return;
    context.read<SettingsCubit>().setProfileBackgroundPath(savedPath);
  }

  void _showBackgroundSheetFixed(BuildContext context) {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_back_outlined),
                title: const Text('Tomar foto para fondo'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickBackgroundImage(rootContext, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir fondo desde galeria'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickBackgroundImage(rootContext, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar fondo'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  rootContext
                      .read<SettingsCubit>()
                      .setProfileBackgroundPath(null);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGamificationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dashboard = _gamificationDashboard;
        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.borderWithOverlay(0.12, lightAlpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadowWithOverlay(0.38, lightAlpha: 0.14),
                blurRadius: 24,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: dashboard == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: scheme.overlayOnSurface(0.18, lightAlpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Logros y ranking',
                      style: TextStyle(
                        color: scheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Todo se guarda localmente en este dispositivo.',
                      style: TextStyle(
                        color: scheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView(
                        children: [
                          _AchievementGroup(
                            title:
                                'Desbloqueados (${dashboard.unlockedAchievements.length})',
                            achievements: dashboard.unlockedAchievements,
                            emptyLabel: 'Todavia no has desbloqueado logros.',
                            unlocked: true,
                          ),
                          const SizedBox(height: 16),
                          _AchievementGroup(
                            title:
                                'Bloqueados (${dashboard.lockedAchievements.length})',
                            achievements: dashboard.lockedAchievements,
                            emptyLabel: 'No hay logros bloqueados.',
                            unlocked: false,
                          ),
                          const SizedBox(height: 16),
                          _RankingSection(ranking: dashboard.ranking),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final settingsState = context.watch<SettingsCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    final bgPath = settingsState.settings.profileBackgroundPath;
    final sessionUserId = authState is AuthSuccess
        ? int.tryParse(authState.user.id) ?? _session.userId
        : _session.userId;
    final userName =
        authState is AuthSuccess ? authState.user.name : _session.userName;
    final userEmail =
        authState is AuthSuccess ? authState.user.email : _session.userEmail;
    final dashboard = _gamificationDashboard;
    final progress = dashboard?.progress;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: scheme.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: scheme.pageGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header fijo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.overlayOnSurface(0.1, lightAlpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.borderWithOverlay(0.2, lightAlpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Perfil',
                              style: TextStyle(
                                color: scheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Gestiona tu cuenta',
                              style: TextStyle(
                                color: scheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showGamificationSheet,
                        icon: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.32),
                            ),
                          ),
                          child: const Icon(
                            Icons.emoji_events_outlined,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        tooltip: 'Ver logros y ranking',
                      ),
                    ],
                  ),
                ),
              ),
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Tarjeta principal del perfil con altura máxima
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final availableHeight = screenHeight * 0.45;
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: availableHeight,
                            ),
                            child: GestureDetector(
                              onTap: () => _showBackgroundSheetFixed(context),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: scheme.overlayOnSurface(
                                    0.1,
                                    lightAlpha: 0.04,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: scheme.borderWithOverlay(
                                      0.2,
                                      lightAlpha: 0.08,
                                    ),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.shadowWithOverlay(
                                        0.1,
                                        lightAlpha: 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  image: bgPath == null || bgPath.isEmpty
                                      ? null
                                      : DecorationImage(
                                          image: FileImage(File(bgPath)),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bgPath == null || bgPath.isEmpty
                                        ? Colors.transparent
                                        : scheme.shadowWithOverlay(
                                            0.42,
                                            lightAlpha: 0.18,
                                          ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _showAvatarSheetFixed(context),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: scheme.borderWithOverlay(
                                                  0.4,
                                                  lightAlpha: 0.18,
                                                ),
                                                width: 2.5,
                                              ),
                                            ),
                                            child:
                                                const ProfileAvatar(radius: 32),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          userName.isEmpty
                                              ? 'Usuario'
                                              : userName,
                                          style: TextStyle(
                                            color: scheme.textPrimary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          userEmail.isEmpty
                                              ? 'Sin correo disponible'
                                              : userEmail,
                                          style: TextStyle(
                                            color: scheme.textSecondary,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.local_fire_department,
                                                size: 13,
                                                color: Color(0xFF10B981),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                sessionUserId > 0
                                                    ? 'Usuario activo'
                                                    : 'Sesion local',
                                                style: const TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _ProfileProgressCard(
                                          progress: progress,
                                          unlockedAchievements:
                                              dashboard?.unlockedCount ?? 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Opciones del perfil
                      _buildProfileOption(
                        context,
                        'Configuracion',
                        Icons.settings_outlined,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      _buildProfileOption(
                        context,
                        'Notificaciones',
                        Icons.notifications_outlined,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                      ),
                      _buildProfileOption(
                        context,
                        'Privacidad',
                        Icons.privacy_tip_outlined,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        ),
                      ),
                      _buildProfileOption(
                        context,
                        'Ayuda y Soporte',
                        Icons.help_outline,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        ),
                      ),
                      _buildProfileOption(
                        context,
                        'Acerca de',
                        Icons.info_outline,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildProfileOption(
                        context,
                        'Cerrar Sesion',
                        Icons.logout,
                        () => _showLogoutDialog(context),
                        isDestructive: true,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.1, lightAlpha: 0.04),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: scheme.borderWithOverlay(0.2, lightAlpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadowWithOverlay(0.1, lightAlpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: (isDestructive ? Colors.red : const Color(0xFF6B46C1))
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(17.5),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF6B46C1),
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : scheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: scheme.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cerrar Sesion',
          style: TextStyle(color: scheme.textPrimary),
        ),
        content: Text(
          'Estas seguro de que quieres cerrar sesion?',
          style: TextStyle(color: scheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: scheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Cerrar Sesion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileProgressCard extends StatelessWidget {
  final GamificationUserProgress? progress;
  final int unlockedAchievements;

  const _ProfileProgressCard({
    required this.progress,
    required this.unlockedAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = progress?.level ?? 1;
    final coins = progress?.coins ?? 0;
    final xpProgress = progress?.xpProgress ?? 0;
    final currentLevelXp = progress?.currentLevelXp ?? 0;
    final xpForNextLevel = progress?.xpForNextLevel ?? 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.18, lightAlpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.borderWithOverlay(0.12, lightAlpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ProfileStatTile(
                  label: 'Nivel',
                  value: '$level',
                  icon: Icons.stars_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ProfileStatTile(
                  label: 'Coins',
                  value: '$coins',
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ProfileStatTile(
                  label: 'Logros',
                  value: '$unlockedAchievements',
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'XP',
                style: TextStyle(
                  color: scheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$currentLevelXp / $xpForNextLevel',
                style: TextStyle(
                  color: scheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: xpProgress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: scheme.overlayOnSurface(0.12, lightAlpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF8B5CF6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: scheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: scheme.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementGroup extends StatelessWidget {
  final String title;
  final List<AchievementStatus> achievements;
  final String emptyLabel;
  final bool unlocked;

  const _AchievementGroup({
    required this.title,
    required this.achievements,
    required this.emptyLabel,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = unlocked ? const Color(0xFF10B981) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.05, lightAlpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.borderWithOverlay(0.08, lightAlpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: scheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (achievements.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(
                color: scheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ...achievements.map(
            (achievement) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.overlayOnSurface(0.12, lightAlpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unlocked
                          ? Icons.verified_rounded
                          : Icons.lock_outline_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.definition.title,
                          style: TextStyle(
                            color: scheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.definition.description,
                          style: TextStyle(
                            color: scheme.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final List<LocalRankingEntry> ranking;

  const _RankingSection({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.05, lightAlpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.borderWithOverlay(0.08, lightAlpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ranking local',
            style: TextStyle(
              color: scheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (ranking.isEmpty)
            Text(
              'Todavia no hay usuarios con progreso local.',
              style: TextStyle(
                color: scheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ...ranking.take(10).map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: entry.isCurrentUser
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.16)
                        : scheme.overlayOnSurface(0.12, lightAlpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: entry.isCurrentUser
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
                          : scheme.borderWithOverlay(0.06, lightAlpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: scheme.overlayOnSurface(0.08, lightAlpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '#${entry.position}',
                            style: TextStyle(
                              color: scheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.userName,
                              style: TextStyle(
                                color: scheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Nivel ${entry.level}  |  ${entry.xpTotal} XP  |  ${entry.coins} coins',
                              style: TextStyle(
                                color: scheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.isCurrentUser)
                        const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SessionProfileData {
  final int userId;
  final String userName;
  final String userEmail;

  const _SessionProfileData({
    this.userId = 0,
    this.userName = 'Usuario',
    this.userEmail = 'Sin correo disponible',
  });
}
