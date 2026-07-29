import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required Widget page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = false,
    this.centerTitle = true,
    this.backgroundColor,
    this.sliver = false,
    this.header,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool sliver;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (sliver) {
      return Scaffold(
        backgroundColor: backgroundColor ?? AppColors.background,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            if (header != null) SliverToBoxAdapter(child: header),
            SliverToBoxAdapter(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              centerTitle: centerTitle,
              leading: showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              actions: actions,
            )
          : null,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }
}
