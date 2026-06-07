import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Prosty stan przechowujący aktualny motyw (jasny/ciemny/systemowy)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);