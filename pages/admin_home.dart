import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _urlCtrl     = TextEditingController();
  final _newUserCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _amountCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    _newUserCtrl.dispose();
    _newPassCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _logout() {
    Provider.of<AppProvider>(context, listen: false).logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  // ── Add Course ──────────────────────────────────────────────
  Future<void> _addCourse(AppProvider prov) async {
    final title     = _titleCtrl.text.trim();
    final desc      = _descCtrl.text.trim();
    final price     = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final url       = _urlCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (title.isEmpty || desc.isEmpty || url.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    await prov.addCourse(Course(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        price: price,
        videoUrl: url));

    messenger.showSnackBar(
        const SnackBar(content: Text('Course added successfully!')));
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _urlCtrl.clear();
  }

  // ── Add Student dialog ──────────────────────────────────────
  void _showAddStudentDialog(AppProvider prov) {
    _newUserCtrl.clear();
    _newPassCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _newUserCtrl,
                decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            TextField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create'),
            onPressed: () => _addUser(
                Provider.of<AppProvider>(context, listen: false),
                ctx,
                UserRole.student),
          ),
        ],
      ),
    );
  }

  // ── Add Teacher dialog ──────────────────────────────────────
  void _showAddTeacherDialog(AppProvider prov) {
    _newUserCtrl.clear();
    _newPassCtrl.clear();
    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add New Teacher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: _newUserCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration:
                    const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 16),
                const Text('Assign Courses:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...prov.courses.map((c) => CheckboxListTile(
                  dense: true,
                  title: Text(c.title),
                  value: selectedIds.contains(c.id),
                  onChanged: (v) => setDlg(() => v == true
                      ? selectedIds.add(c.id)
                      : selectedIds.remove(c.id)),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => _addUser(
                Provider.of<AppProvider>(context, listen: false),
                ctx,
                UserRole.teacher,
                assignedCourseIds: selectedIds.toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared add-user logic ────────────────────────────────────
  Future<void> _addUser(
      AppProvider prov,
      BuildContext dialogCtx,
      UserRole role, {
        List<String> assignedCourseIds = const [],
      }) async {
    final username  = _newUserCtrl.text.trim();
    final password  = _newPassCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final nav       = Navigator.of(dialogCtx);

    if (username.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final bool ok;
    if (role == UserRole.teacher) {
      ok = await prov.addTeacher(username, password, assignedCourseIds);
    } else {
      ok = await prov.addStudent(username, password);
    }

    if (!ok) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Username already exists!')));
      return;
    }

    nav.pop();
    final label = role == UserRole.teacher ? 'Teacher' : 'Student';
    messenger.showSnackBar(
        SnackBar(content: Text('$label created successfully!')));
  }

  // ── Edit teacher course assignments ─────────────────────────
  void _showEditTeacherCoursesDialog(AppProvider prov, User teacher) {
    final selectedIds = <String>{...teacher.assignedCourseIds};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Courses for ${teacher.username}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: prov.courses
                  .map((c) => CheckboxListTile(
                dense: true,
                title: Text(c.title),
                value: selectedIds.contains(c.id),
                onChanged: (v) => setDlg(() => v == true
                    ? selectedIds.add(c.id)
                    : selectedIds.remove(c.id)),
              ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                final nav = Navigator.of(ctx);
                await prov.updateTeacherCourses(
                    teacher.id, selectedIds.toList());
                nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Remove user ──────────────────────────────────────────────
  Future<void> _confirmRemove(AppProvider prov, User u) async {
    final messenger = ScaffoldMessenger.of(context);
    final typeLabel = u.isTeacher ? 'Teacher' : 'Student';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $typeLabel'),
        content: Text('Remove "${u.username}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await prov.removeUser(u.id);
      messenger.showSnackBar(SnackBar(
          content: Text(ok
              ? '${u.username} removed.'
              : 'Could not remove user.')));
    }
  }

  // ── Generate payment code ────────────────────────────────────
  void _showGenerateCodeDialog(AppProvider prov) {
    final outerMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Payment Code'),
        content: TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (\$)'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _amountCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Generate'),
            onPressed: () async {
              final amount =
                  double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
              if (amount <= 0) {
                outerMessenger.showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')));
                return;
              }
              final nav     = Navigator.of(ctx);
              final newCode = await prov.generateCode(amount);
              _amountCtrl.clear();
              nav.pop();
              outerMessenger.showSnackBar(SnackBar(
                  content: Text(
                      'Code: ${newCode.code}  (\$${newCode.amount.toStringAsFixed(2)})')));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov     = Provider.of<AppProvider>(context);
    final students = prov.students;
    final teachers = prov.teachers;
    final courses  = prov.courses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(icon: Icon(Icons.people),          text: 'Students'),
            Tab(icon: Icon(Icons.school),          text: 'Teachers'),
            Tab(icon: Icon(Icons.menu_book),       text: 'Courses'),
            Tab(icon: Icon(Icons.add),             text: 'Add Course'),
            Tab(icon: Icon(Icons.monetization_on), text: 'Codes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [

          // ── Students ─────────────────────────────────────
          Column(children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
              onPressed: () => _showAddStudentDialog(prov),
            ),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('No students yet.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final u = students[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person,
                          color: Colors.indigo),
                      title: Text(u.username),
                      subtitle: Text(
                          'Balance: \$${u.balance.toStringAsFixed(2)}'
                              '  •  ${u.purchasedCourseIds.length} course(s)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          roleBadge(u.role),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: () =>
                                _confirmRemove(prov, u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),

          // ── Teachers ─────────────────────────────────────
          Column(children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Teacher'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => _showAddTeacherDialog(prov),
            ),
            Expanded(
              child: teachers.isEmpty
                  ? const Center(child: Text('No teachers yet.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: teachers.length,
                itemBuilder: (_, i) {
                  final u = teachers[i];
                  final assigned = prov.courses
                      .where((c) =>
                      u.assignedCourseIds.contains(c.id))
                      .map((c) => c.title)
                      .join(', ');
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.school,
                          color: Colors.teal),
                      title: Text(u.username),
                      subtitle: Text(assigned.isEmpty
                          ? 'No courses assigned'
                          : assigned),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          roleBadge(u.role),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.teal),
                            tooltip: 'Edit courses',
                            onPressed: () =>
                                _showEditTeacherCoursesDialog(
                                    prov, u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: () =>
                                _confirmRemove(prov, u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),

          // ── Courses list ─────────────────────────────────
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: courses.length,
            itemBuilder: (_, i) {
              final c = courses[i];
              final teacherName = prov.teachers
                  .where((t) => t.assignedCourseIds.contains(c.id))
                  .map((t) => t.username)
                  .join(', ');
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill,
                      color: Colors.indigo),
                  title: Text(c.title),
                  subtitle: Text(teacherName.isEmpty
                      ? c.description
                      : '${c.description}\nTeacher: $teacherName'),
                  isThreeLine: teacherName.isNotEmpty,
                  trailing: Text('\$${c.price.toStringAsFixed(2)}',
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),

          // ── Add Course ───────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Course',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Course Title')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _descCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: 'Price (\$)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _urlCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Video URL')),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _addCourse(prov),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Course'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Payment Codes ────────────────────────────────
          Column(children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Generate Code'),
              onPressed: () => _showGenerateCodeDialog(prov),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: prov.codes.isEmpty
                  ? const Center(child: Text('No payment codes yet.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: prov.codes.length,
                itemBuilder: (context, i) {
                  final pc = prov.codes[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        pc.used
                            ? Icons.check_circle
                            : Icons.pending,
                        color: pc.used
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text('Code: ${pc.code}'),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Amount: \$${pc.amount.toStringAsFixed(2)}'),
                          Text('Created: ${pc.createdAt}'),
                          if (pc.used)
                            Text(
                                'Used by: ${pc.usedBy} on ${pc.usedAt}'),
                        ],
                      ),
                      trailing: pc.used
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                              content: Text(
                                  'Code: ${pc.code}')));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
