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

  late List<Map<String, dynamic>> _allUsers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(context, listen: false).reloadUsers();
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
    final passwordController = TextEditingController(text: 'password123');
    final creditsController = TextEditingController(text: '5');
    String role = 'admin';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Agregar Nuevo Usuario'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Rol de Acceso',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'client', child: Text('CLIENTE')),
                        DropdownMenuItem(value: 'admin', child: Text('ADMINISTRADOR')),
                        DropdownMenuItem(value: 'root', child: Text('ROOT (SUPERUSUARIO)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            role = val;
                            if (role != 'client') {
                              creditsController.text = '999';
                            } else {
                              creditsController.text = '5';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: creditsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Créditos Disponibles',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña Inicial',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final pass = passwordController.text.trim();
                    final creds = int.tryParse(creditsController.text.trim()) ?? (role == 'client' ? 5 : 999);

                    if (name.isEmpty || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor completa todos los campos requeridos.')),
                      );
                      return;
                    }

                    final state = Provider.of<AppStateProvider>(context, listen: false);
                    await state.createUserFromAdmin(
                      name,
                      email,
                      role,
                      creds,
                      pass.isNotEmpty ? pass : 'password123',
                    );

                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Usuario "$name" creado en la base de datos.')),
                      );
                    }
                  },
                  child: const Text('Crear Usuario'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(int index, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']?.toString() ?? '');
    final creditsController = TextEditingController(text: (user['credits'] ?? 5).toString());
    final passwordController = TextEditingController();
    String role = user['role']?.toString() ?? 'client';
    final email = (user['email'] ?? '').toString();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.goldAccent),
                  SizedBox(width: 8),
                  Text('Editar Usuario'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo (no modificable)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'client', child: Text('CLIENTE')),
                        DropdownMenuItem(value: 'admin', child: Text('ADMINISTRADOR')),
                        DropdownMenuItem(value: 'root', child: Text('ROOT (SUPERUSUARIO)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            role = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: creditsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Créditos Disponibles',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Nueva Contraseña (opcional)',
                        hintText: 'Dejar vacío para mantener la actual',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final credStr = creditsController.text.trim();
                    final creds = int.tryParse(credStr) ?? (user['credits'] as int? ?? 5);
                    final pass = passwordController.text.trim();

                    final state = Provider.of<AppStateProvider>(context, listen: false);
                    await state.updateUserRoleAndCredits(
                      email,
                      role,
                      creds,
                      name.isNotEmpty ? name : null,
                      pass.isNotEmpty ? pass : null,
                    );

                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario actualizado en la base de datos.')),
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

  void _confirmDeleteUser(Map<String, dynamic> user) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final email = (user['email'] ?? '').toString();
    final name = (user['name'] ?? 'Usuario').toString();

    if (email.toLowerCase() == state.userEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.redAccent,
          content: Text('No puedes eliminar la cuenta de superusuario con la que has iniciado sesión.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Eliminar usuario?'),
          content: Text(
            '¿Estás seguro de que deseas eliminar la cuenta de "$name" ($email)? Esta acción eliminará su acceso y créditos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await state.deleteUser(email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.redAccent,
                    content: Text('Usuario "$name" eliminado del sistema.'),
                  ),
                );
              },
              child: const Text('Eliminar', style: TextStyle(color: AppTheme.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load dynamic users list from database state
    _allUsers = state.users.isNotEmpty
        ? state.users
        : [
            {'name': 'Root Admin', 'email': 'root@myapp.com', 'role': 'root', 'credits': 999},
            {'name': 'Admin General', 'email': 'admin@myapp.com', 'role': 'admin', 'credits': 999},
            {'name': 'Valentina López', 'email': 'cliente_prueba@email.com', 'role': 'client', 'credits': state.credits},
          ];

    // Filter list
    final filteredUsers = _allUsers.where((u) {
      final q = _searchQuery.toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final name = (u['name'] ?? '').toString().toLowerCase();
      final nameMatches = email.contains(q) || name.contains(q);

      final tabIndex = _tabController.index;
      if (tabIndex == 0) return nameMatches; // Todos
      if (tabIndex == 1) return nameMatches && u['role'] == 'client';
      if (tabIndex == 2) return nameMatches && u['role'] == 'admin';
      if (tabIndex == 3) return nameMatches && u['role'] == 'root';
      return nameMatches;
    }).toList();

    final totalUsersCount = _allUsers.length;
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
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26, color: Colors.white),
              tooltip: 'Agregar Usuario',
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
                Tab(text: 'Clientes'),
                Tab(text: 'Admins'),
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
                  '$totalUsersCount cuentas registradas',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$adminsCount con privilegios de gestión',
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

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => state.reloadUsers(),
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron usuarios en esta categoría.',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showAddUserDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Crear Usuario'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final name = (user['name'] ?? 'Usuario').toString();
                        final email = (user['email'] ?? '').toString();
                        final role = (user['role'] ?? 'client').toString();
                        final credits = (user['credits'] as int?) ?? 5;

                        // Display initials
                        final initials = name.isNotEmpty
                            ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withValues(alpha: 0.1),
                              child: Text(initials, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                                Text(
                                  email,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role == 'client' ? 'Créditos: $credits' : 'Créditos: Ilimitados (∞)',
                                  style: TextStyle(
                                    color: role == 'client' ? AppTheme.primaryColor : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.goldAccent, size: 20),
                                  tooltip: 'Editar usuario',
                                  onPressed: () => _showEditUserDialog(index, user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.redAccent, size: 20),
                                  tooltip: 'Eliminar usuario',
                                  onPressed: () => _confirmDeleteUser(user),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
