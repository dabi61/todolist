import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_list_flutter/presentation/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
  ],
);
