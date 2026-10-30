import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// A full page in the "Clock Radio" look: a large title with an optional
/// subtitle and keys, over the page content. It draws its own header
/// instead of an `AppBar`, so large text makes it taller instead of
/// squeezing it, and it sets the status bar icons from the theme.
class AppPage extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.actions = const [],
    super.key,
  });

  final String title;

  /// A short line under the title.
  final String? subtitle;

  /// Replaces the back key that a page opened on top of another gets.
  final Widget? leading;

  /// Keys at the end of the header, such as Settings.
  final List<Widget> actions;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final leading = this.leading ?? (canGoBack ? const BackButton() : null);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        // The bottom inset includes the tab tray, if there is one.
        body: SafeArea(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: Spacing.lg,
                  top: Spacing.lg,
                  right: Spacing.lg,
                  bottom: Spacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: .start,
                  spacing: Spacing.md,
                  children: [
                    ?leading,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Semantics(
                            header: true,
                            namesRoute: true,
                            child: Text(
                              title,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          if (subtitle case final subtitle?)
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
