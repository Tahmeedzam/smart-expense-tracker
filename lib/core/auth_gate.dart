import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/repository_providers.dart';
import 'package:expense_tracker/screens/login_screen.dart';
import 'package:expense_tracker/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    ref
        .read(categoryRepositoryProvider)
        .fetchAll()
        .then((cats) => print('CATS: ${cats.length}'));

    return authState.when(
      data: (state) {
        final session =
            state.session ?? Supabase.instance.client.auth.currentSession;
        return session != null ? const BottomNavbar() : const LoginScreen();
      },

      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
    );
  }
}
