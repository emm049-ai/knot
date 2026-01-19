import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KnotAppBar extends AppBar {
  KnotAppBar({
    super.key,
    required BuildContext context,
    required String titleText,
    Widget? titleWidget,
    bool showHome = true,
    List<Widget>? extraActions,
  }) : super(
          title: titleWidget ?? Text(titleText),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          actions: [
            if (extraActions != null) ...extraActions,
            if (showHome)
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go('/home'),
              ),
          ],
        );
}
