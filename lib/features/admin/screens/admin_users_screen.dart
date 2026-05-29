import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simulated list of users in the system since we have a mock environment
    final List<Map<String, dynamic>> mockUsers = [
      {'email': 'cliente_prueba@email.com', 'name': 'Valentina López', 'role': 'client', 'credits': state.credits},
      {'email': 'maria.g@gmail.com', 'name': 'María Gutiérrez', 'role': 'client', 'credits': 12},
      {'email': 'carlos.p@gmail.com', 'name': 'Carlos Pérez', 'role': 'client', 'credits': 3},
      {'email': 'laura.m@gmail.com', 'name': 'Laura Medina', 'role': 'client', 'credits': 8},
      {'email': 'juan.r@gmail.com', 'name': 'Juan Rodríguez', 'role': 'client', 'credits': 5},
      {'email': 'admin@email.com', 'name': 'Admin General', 'role': 'admin', 'credits': 999},
    ];

    final filteredUsers = mockUsers.where((u) {
      return u['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar usuario por nombre o correo...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // User counts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredUsers.length} cuentas registradas',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron usuarios.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final name = user['name'] as String;
                      final email = user['email'] as String;
                      final role = user['role'] as String;
                      final credits = user['credits'] as int;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar circle with initials
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // User Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (role == 'admin' ? AppTheme.goldAccent : AppTheme.primaryColor).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        role == 'admin' ? 'Administrador' : 'Cliente',
                                        style: TextStyle(
                                          color: role == 'admin' ? AppTheme.goldAccent : AppTheme.primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Credits & Actions
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    role == 'admin' ? 'Créditos: ∞' : 'Créditos: $credits',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  if (role == 'client')
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (email == 'cliente_prueba@email.com') {
                                          await state.setUserCredits(credits + 5);
                                        }
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Se agregaron 5 créditos a $name')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        foregroundColor: AppTheme.primaryColor,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('+5 Créditos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
