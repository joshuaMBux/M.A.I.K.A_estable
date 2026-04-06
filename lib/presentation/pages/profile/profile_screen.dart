import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/settings/settings_cubit.dart';
import '../auth/auth_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import '../../widgets/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Guarda la imagen escogida en un directorio propio de la app
  /// y devuelve la ruta final que sí será estable en el tiempo.
  Future<String> _persistPickedImage(
    XFile picked, {
    required String prefix,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.name.isNotEmpty ? picked.name : picked.path);
    final fileName =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}${ext.isNotEmpty ? ext : '.jpg'}';
    final target = File(p.join(appDir.path, 'profile', fileName));

    // Asegurar que exista la carpeta 'profile'
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }

    final bytes = await picked.readAsBytes();
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return;
    final savedPath =
        await _persistPickedImage(picked, prefix: 'avatar');
    // Actualiza settings (y se guarda en SharedPreferences)
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
                title: const Text('Elegir de galer\u00eda'),
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
                  rootContext
                      .read<SettingsCubit>()
                      .setProfileImagePath(null);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<SettingsCubit>().setProfileImagePath(null);
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
    final savedPath =
        await _persistPickedImage(picked, prefix: 'bg');
    context
        .read<SettingsCubit>()
        .setProfileBackgroundPath(savedPath);
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
                title: const Text('Elegir fondo desde galer\u00eda'),
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

  void _showBackgroundSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_back_outlined),
                title: const Text('Tomar foto para fondo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickBackgroundImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir fondo desde galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickBackgroundImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar fondo'),
                onTap: () {
                  Navigator.of(context).pop();
                  context
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Usuario Demo';
    String userEmail = 'demo@example.com';
    if (authState is AuthSuccess) {
      userName = authState.user.name;
      userEmail = authState.user.email;
    }

    final settingsState = context.watch<SettingsCubit>().state;
    final bgPath = settingsState.settings.profileBackgroundPath;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mi Perfil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Gestiona tu cuenta',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showBackgroundSheetFixed(context),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: bgPath == null || bgPath.isEmpty
                            ? null
                            : DecorationImage(
                                image: FileImage(
                                  // ignore: prefer_interpolation_to_compose_strings
                                  File(bgPath),
                                ),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: bgPath == null || bgPath.isEmpty
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showAvatarSheetFixed(context),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.4),
                                    width: 3,
                                  ),
                                ),
                                child: const ProfileAvatar(radius: 38),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
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
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Usuario activo',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildProfileOption(
                          context,
                          'Configuración',
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
                        const SizedBox(height: 16),
                        _buildProfileOption(
                          context,
                          'Cerrar Sesión',
                          Icons.logout,
                          () => _showLogoutDialog(context),
                          isDestructive: true,
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

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
            color: isDestructive ? Colors.red : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
