import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:myapp/src/admin_app/admin_dashboard_screen.dart';
import 'package:myapp/src/admin_app/article_form_screen.dart'; // Import ArticleFormScreen
import 'package:myapp/src/auth/login_screen.dart';
import 'package:myapp/src/user_app/user_home_screen.dart';
import 'package:myapp/src/services/auth_service.dart'; // Import AuthService
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase User

GoRouter buildRouter(AuthService authService) {
  return GoRouter(
    refreshListenable: authService, // Listen to auth state changes
    redirect: (BuildContext context, GoRouterState state) async {
      developer.log('GoRouter Redirect: state.matchedLocation = ${state.matchedLocation}', name: 'AppRouter');
      final bool loggedIn = authService.user != null;
      developer.log('GoRouter Redirect: loggedIn = $loggedIn', name: 'AppRouter');

      bool isAdminUser = false;
      if (loggedIn) {
        final User? currentUser = authService.user;
        if (currentUser != null) {
          try {
            isAdminUser = await authService.isAdmin(currentUser);
          } catch (e, s) {
            developer.log('GoRouter Redirect: Error checking isAdmin: $e', error: e, stackTrace: s, name: 'AppRouter');
            return '/login'; // Redirect to login on error
          }
        } else {
          developer.log('GoRouter Redirect: loggedIn is true but authService.user is null unexpectedly.', name: 'AppRouter');
          return '/login'; // Unexpected state, redirect to login
        }
      }
      developer.log('GoRouter Redirect: isAdminUser = $isAdminUser', name: 'AppRouter');

      final bool goingToLogin = state.matchedLocation == '/login';
      final bool goingToAdmin = state.matchedLocation.startsWith('/admin');

      if (!loggedIn) {
        developer.log('GoRouter Redirect: Not logged in. Redirecting to ${goingToLogin ? 'null (login page)' : '/login'}', name: 'AppRouter');
        return goingToLogin ? null : '/login';
      }

      if (loggedIn) {
        if (goingToLogin) {
          developer.log('GoRouter Redirect: Logged in, going to login. Redirecting to /', name: 'AppRouter');
          return '/';
        }
        if (goingToAdmin && !isAdminUser) {
          developer.log('GoRouter Redirect: Logged in, going to admin but not admin user. Redirecting to /', name: 'AppRouter');
          return '/';
        }
      }

      developer.log('GoRouter Redirect: No redirect needed. Current location: ${state.matchedLocation}', name: 'AppRouter');
      return null;
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
