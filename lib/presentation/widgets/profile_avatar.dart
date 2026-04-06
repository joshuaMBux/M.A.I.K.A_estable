import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings/settings_cubit.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.radius = 40});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) =>
          previous.settings.profileImagePath !=
          current.settings.profileImagePath,
      builder: (context, state) {
        final path = state.settings.profileImagePath;
        if (path == null || path.isEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFF6B46C1),
            child: Icon(Icons.person, size: radius, color: Colors.white),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(File(path)),
        );
      },
    );
  }
}

