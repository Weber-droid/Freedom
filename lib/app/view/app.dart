import 'package:flutter/material.dart';
import 'package:freedom/l10n/l10n.dart';
import 'package:freedom/router/router.dart';
import 'package:freedom/shared/theme/dark_theme.dart';
import 'package:freedom/shared/theme/light_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: getLightTheme,
      darkTheme:getDarkTheme ,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
