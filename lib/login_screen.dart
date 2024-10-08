import 'package:flutter/material.dart';
import 'package:djangoflow_odoo_oauth/djangoflow_odoo_oauth.dart';
import 'package:djangoflow_odoo_auth/djangoflow_odoo_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  final String baseUrl = 'https://us.apexive.com';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Column(
        children: [
          BlocBuilder<DjangoflowOdooAuthCubit, DjangoflowOdooAuthState>(
            builder: (context, state) {
              if (state.status == AuthStatus.initial ||
                  state.status == AuthStatus.unauthenticated) {
                return Center(
                  child: ElevatedButton(
                    child: const Text('Login with SSO'),
                    onPressed: () => _handleSSOLogin(context),
                  ),
                );
              }
              print(state.session?.toJson());
              return Column(
                children: [
                  Text(
                    'Session ID: ${state.session?.id}',
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'UserName: ${state.session?.userName}',
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    child: const Text('Logout'),
                    onPressed: () async {
                      await context.read<DjangoflowOdooAuthCubit>().logout();
                      await OdooSSOAuthenticator().logout();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleSSOLogin(BuildContext context) async {
    final authenticator = OdooSSOAuthenticator();
    final authCubit = context.read<DjangoflowOdooAuthCubit>();

    authCubit.setBaseUrl(baseUrl);
    try {
      final sessionId =
          await authenticator.authenticate(context, baseUrl: baseUrl);
      if (sessionId != null) {
        await authCubit.loginWithSessionId(sessionId);
        print('OAuth login successful!');
        // Navigate to home screen or perform other actions
      } else {
        print('Failed to obtain session ID');
      }
    } catch (e) {
      print('OAuth login failed: $e');
      // Show error message to user
    }
  }
}
