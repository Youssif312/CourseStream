import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';
import 'video_player_page.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _urlCtrl     = TextEditingController();
  final _newPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  void _logout() {
    Provider.of<AppProvider>(context, listen: false).logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

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

    final course = Course(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        price: price,
        videoUrl: url);

    await prov.addCourse(course);
    await prov.updateTeacherCourses(
      prov.currentUser!.id,
      [...prov.currentUser!.assignedCourseIds, course.id],
    );

    messenger.showSnackBar(
        const SnackBar(content: Text('Course added and assigned to you!')));
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _urlCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final prov    = Provider.of<AppProvider>(context);
    final teacher = prov.currentUser!;
    final myCourses = prov.courses
        .where((c) => teacher.assignedCourseIds.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher: ${teacher.username}'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book),  text: 'My Courses'),
            Tab(icon: Icon(Icons.add_circle), text: 'Add Course'),
            Tab(icon: Icon(Icons.person),     text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── My Courses ─────────────────────────────────────
          myCourses.isEmpty
              ? const Center(child: Text('No courses assigned to you yet.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: myCourses.length,
            itemBuilder: (_, i) {
              final c = myCourses[i];
              return CourseCard(
                course: c,
                trailing: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VideoPlayerPage(
                                videoUrl: c.videoUrl,
                                title: c.title)));
                    await SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.portraitUp]);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal),
                  child: const Text('Preview'),
                ),
              );
            },
          ),

          // ── Add Course ─────────────────────────────────────
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
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Profile ────────────────────────────────────────
          TeacherProfileTab(
              teacher: teacher, prov: prov, newPassCtrl: _newPassCtrl),
        ],
      ),
    );
  }
}
