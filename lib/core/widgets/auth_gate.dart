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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.initializationError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo conectar con Firebase. La app no usará datos locales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  state.initializationError!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.retryInitialization,
                  child: const Text('Reintentar conexión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!state.isAuthenticated) {
      return const WelcomeScreen();
    }

    if (state.maintenanceMode &&
        state.userRole != 'admin' &&
        state.userRole != 'root') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_circle_outlined, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'La aplicación está en mantenimiento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vuelve a intentarlo más tarde.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: state.logoutUser,
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
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
