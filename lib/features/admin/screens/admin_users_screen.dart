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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(context, listen: false).reloadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final creditsController = TextEditingController(text: '5');
    final passwordController = TextEditingController(text: 'password123');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFFE61D63)),
              SizedBox(width: 8),
              Text('Registrar Cliente'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    hintText: 'Ej. Juan Pérez',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'ejemplo@correo.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: creditsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Créditos iniciales',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stars_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña de acceso',
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
                backgroundColor: const Color(0xFFE61D63),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final creds = int.tryParse(creditsController.text.trim()) ?? 5;
                final pass = passwordController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa nombre y correo.')),
                  );
                  return;
                }

                final state = Provider.of<AppStateProvider>(context, listen: false);
                await state.createUserFromAdmin(
                  name,
                  email,
                  'client',
                  creds,
                  pass.isNotEmpty ? pass : 'password123',
                );

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cliente "$name" registrado exitosamente.')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditClientDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']?.toString() ?? '');
    final creditsController = TextEditingController(text: (user['credits'] ?? 5).toString());
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFFE61D63)),
              SizedBox(width: 8),
              Text('Editar Cliente'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: user['email']?.toString() ?? '',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo (no modificable)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: creditsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Créditos disponibles',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stars_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña (opcional)',
                    hintText: 'Dejar vacío para no cambiar',
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
                backgroundColor: const Color(0xFFE61D63),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final creds = int.tryParse(creditsController.text.trim()) ?? (user['credits'] as int? ?? 5);
                final pass = passwordController.text.trim();
                final email = (user['email'] ?? '').toString();

                final state = Provider.of<AppStateProvider>(context, listen: false);
                await state.updateUserRoleAndCredits(
                  email,
                  'client',
                  creds,
                  name.isNotEmpty ? name : null,
                  pass.isNotEmpty ? pass : null,
                );

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Datos de "$name" actualizados.')),
                );
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteClient(Map<String, dynamic> user) {
    final name = (user['name'] ?? 'Usuario').toString();
    final email = (user['email'] ?? '').toString();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Eliminar cliente?'),
          content: Text(
            '¿Estás seguro de que deseas eliminar permanentemente la cuenta de "$name" ($email)? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final state = Provider.of<AppStateProvider>(context, listen: false);
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

    // Load live client users from database state
    final clientUsers = state.users.where((u) => u['role'] == 'client').toList();
    final allClients = clientUsers.isNotEmpty
        ? clientUsers
        : [
            {'email': 'cliente_prueba@email.com', 'name': 'Valentina López', 'role': 'client', 'credits': state.credits},
          ];

    final filteredUsers = allClients.where((u) {
      final q = _searchQuery.toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final name = (u['name'] ?? '').toString().toLowerCase();
      return email.contains(q) || name.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE61D63), Color(0xFF7B2CBF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Usuarios Clientes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            tooltip: 'Registrar nuevo cliente',
            onPressed: _showAddClientDialog,
          ),
        ],
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

          // User counts & Add shortcut
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredUsers.length} clientes registrados',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _showAddClientDialog,
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFFE61D63)),
                  label: const Text(
                    'Nuevo Cliente',
                    style: TextStyle(color: Color(0xFFE61D63), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          Icon(Icons.person_off_outlined, size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron usuarios clientes.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showAddClientDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar Cliente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE61D63),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final name = (user['name'] ?? 'Usuario').toString();
                        final email = (user['email'] ?? '').toString();
                        final credits = (user['credits'] as int?) ?? 5;

                        // Initials for avatar
                        final initials = name.isNotEmpty
                            ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                            : 'C';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Avatar circle with initials
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE61D63).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Color(0xFFE61D63),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // User Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE61D63).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'CLIENTE',
                                              style: TextStyle(
                                                color: Color(0xFFE61D63),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Créditos: $credits',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions Column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // +5 Credits Button
                                    ElevatedButton(
                                      onPressed: () async {
                                        await state.addUserCredits(email, 5);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 2),
                                              content: Text('Se agregaron +5 créditos a $name ($email).'),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE61D63).withValues(alpha: 0.1),
                                        foregroundColor: const Color(0xFFE61D63),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text(
                                        '+5 Créditos',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Edit & Delete row
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _showEditClientDialog(user),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[600]),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _confirmDeleteClient(user),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(Icons.delete_outline, size: 18, color: AppTheme.redAccent),
                                          ),
                                        ),
                                      ],
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
          ),
        ],
      ),
    );
  }
}
