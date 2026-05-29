import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../../features/client/screens/navigation_holder.dart';
import '../../features/client/screens/welcome_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/root/screens/root_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!state.isAuthenticated) {
      return const WelcomeScreen();
    }

    // Redirect based on role
    if (state.userRole == 'admin') {
      return const AdminDashboardScreen();
    } else if (state.userRole == 'root') {
      return const RootDashboardScreen();
    }

    return const NavigationHolder();
  }
}
