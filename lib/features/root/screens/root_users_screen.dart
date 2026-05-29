import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';

class RootUsersScreen extends StatefulWidget {
  const RootUsersScreen({super.key});

  @override
  State<RootUsersScreen> createState() => _RootUsersScreenState();
}

class _RootUsersScreenState extends State<RootUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Simulated list of users, including state integration for live client_prueba edits
  late List<Map<String, dynamic>> _allUsers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    String role = 'admin';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar Nuevo Usuario'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre Completo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Rol de Acceso'),
                    items: ['admin', 'root', 'client']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          role = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor completa todos los campos.')),
                      );
                      return;
                    }
                    setState(() {
                      _allUsers.insert(0, {
                        'name': name,
                        'email': email,
                        'role': role,
                        'credits': role == 'client' ? 5 : 999,
                      });
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Usuario "$name" creado con éxito.')),
                    );
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(int index, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final creditsController = TextEditingController(text: user['credits'].toString());
    String role = user['role'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: ['client', 'admin', 'root']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            role = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (role == 'client')
                      TextField(
                        controller: creditsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Créditos Disponibles'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final credStr = creditsController.text.trim();
                    final creds = int.tryParse(credStr) ?? user['credits'];

                    setState(() {
                      _allUsers[index] = {
                        'name': name,
                        'email': user['email'],
                        'role': role,
                        'credits': role == 'client' ? creds : 999,
                      };
                    });

                    // If editing client_prueba, sync with provider
                    if (user['email'] == 'cliente_prueba@email.com') {
                      final state = Provider.of<AppStateProvider>(context, listen: false);
                      await state.setUserCredits(creds);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario actualizado.')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load dynamic users list synced with state credits
    _allUsers = [
      {'name': 'Root Admin', 'email': 'root@myapp.com', 'role': 'root', 'credits': 999},
      {'name': 'Admin General', 'email': 'admin@myapp.com', 'role': 'admin', 'credits': 999},
      {'name': 'Cliente Prueba', 'email': 'cliente_prueba@email.com', 'role': 'client', 'credits': state.credits},
      {'name': 'María González', 'email': 'maria.g@gmail.com', 'role': 'client', 'credits': 12},
      {'name': 'Carlos Pérez', 'email': 'carlos.p@gmail.com', 'role': 'client', 'credits': 3},
      {'name': 'Laura Medina', 'email': 'laura.m@gmail.com', 'role': 'client', 'credits': 8},
      {'name': 'Juan Rodríguez', 'email': 'juan.r@gmail.com', 'role': 'client', 'credits': 5},
    ];

    // Filter list
    final filteredUsers = _allUsers.where((u) {
      final nameMatches = u['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final tabIndex = _tabController.index;
      if (tabIndex == 0) return nameMatches; // Todos
      if (tabIndex == 1) return nameMatches && u['role'] == 'client';
      if (tabIndex == 2) return nameMatches && u['role'] == 'admin';
      if (tabIndex == 3) return nameMatches && u['role'] == 'root';
      return nameMatches;
    }).toList();

    final totalUsersCount = 120 + _allUsers.length;
    final adminsCount = _allUsers.where((u) => u['role'] == 'admin' || u['role'] == 'root').length;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
              onPressed: _showAddUserDialog,
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  hintText: 'Buscar usuario...',
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

          // Custom Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Todos'),
                Tab(text: 'Cliente'),
                Tab(text: 'Admin'),
                Tab(text: 'Root'),
              ],
            ),
          ),

          // Counts row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalUsersCount usuarios totales',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+ $adminsCount administradores',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No se encontraron usuarios.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final name = user['name'] as String;
                      final email = user['email'] as String;
                      final role = user['role'] as String;
                      final credits = user['credits'] as int;

                      // Display initials
                      final initials = name.isNotEmpty
                          ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                          : 'U';

                      Color roleColor;
                      switch (role) {
                        case 'root':
                          roleColor = AppTheme.goldAccent;
                          break;
                        case 'admin':
                          roleColor = AppTheme.primaryColor;
                          break;
                        case 'client':
                        default:
                          roleColor = AppTheme.greenAccent;
                          break;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withValues(alpha: 0.1),
                            child: Text(initials, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                          ),
                          title: Row(
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(color: roleColor, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(email, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              const SizedBox(height: 2),
                              if (role == 'client')
                                Text(
                                  'Créditos: $credits',
                                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.goldAccent, size: 20),
                            onPressed: () => _showEditUserDialog(index, user),
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
