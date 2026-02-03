import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:myapp/src/admin_app/admin_dashboard_screen.dart';
import 'package:myapp/src/admin_app/article_form_screen.dart'; // Import ArticleFormScreen
import 'package:myapp/src/auth/login_screen.dart';
import 'package:myapp/src/user_app/user_home_screen.dart';
import 'package:myapp/src/services/auth_service.dart'; // Import AuthService

GoRouter buildRouter(AuthService authService) {
  return GoRouter(
    refreshListenable: authService, // Listen to auth state changes
    redirect: (BuildContext context, GoRouterState state) async {
      final bool loggedIn = authService.user != null;
      final bool isAdminUser = loggedIn ? await authService.isAdmin(authService.user!) : false;

      final bool goingToLogin = state.matchedLocation == '/login';
      final bool goingToAdmin = state.matchedLocation.startsWith('/admin'); // Check if trying to access any admin path

      // If not logged in
      if (!loggedIn) {
        return goingToLogin ? null : '/login';
      }

      // If logged in
      if (loggedIn) {
        // If going to login, redirect to home
        if (goingToLogin) {
          return '/';
        }
        // If trying to access admin path and not an admin, redirect to home
        if (goingToAdmin && !isAdminUser) {
          return '/';
        }
      }

      return null; // No redirect
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const UserHomeScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminDashboardScreen();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'article_form', // /admin/article_form
            builder: (BuildContext context, GoRouterState state) {
              final String? articleId = state.uri.queryParameters['id'];
              return ArticleFormScreen(articleId: articleId);
            },
          ),
        ],
      ),
    ],
  );
}
