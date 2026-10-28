import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/ui/fonts.dart';

void main() {
  addFontLicenses();
  runApp(const ProviderScope(child: ShuffleAlarmApp()));
}
