import 'package:djangoflow_app/djangoflow_app.dart';
import 'package:djangoflow_odoo_auth/djangoflow_odoo_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_sso/odoo_client_manager.dart';

import 'login_screen.dart';

void main() {
  DjangoflowAppRunner.run(
    onException: (exception, stackTrace) =>
        print('Error: $exception, $stackTrace'),
    rootWidgetBuilder: (builder) {
      return BlocProvider<DjangoflowOdooAuthCubit>(
        create: (context) => DjangoflowOdooAuthCubit(
          DjangoflowOdooAuthRepository(
            CustomOdooClientManager(),
          ),
        ),
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    },
  );
}
