import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';
import 'video_player_page.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _newPassCtrl = TextEditingController();
  final _redeemCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _newPassCtrl.dispose();
    _redeemCtrl.dispose();
    super.dispose();
  }

  void _logout() {
    Provider.of<AppProvider>(context, listen: false).logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AppProvider>(context);
    final user = prov.currentUser!;
    final myCourses = prov.courses
        .where((c) => user.purchasedCourseIds.contains(c.id))
        .toList();
    final available = prov.courses
        .where((c) => !user.purchasedCourseIds.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.username}!'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.book),      text: 'My Courses'),
            Tab(icon: Icon(Icons.menu_book), text: 'Available'),
            Tab(icon: Icon(Icons.person),    text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── My Courses ─────────────────────────────────────
          myCourses.isEmpty
              ? const Center(
              child: Text("You haven't purchased any courses yet."))
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
                      backgroundColor: Colors.green),
                  child: const Text('Watch'),
                ),
              );
            },
          ),

          // ── Available ──────────────────────────────────────
          available.isEmpty
              ? const Center(child: Text('No available courses to buy.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: available.length,
            itemBuilder: (_, i) {
              final c = available[i];
              return CourseCard(
                course: c,
                trailing: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (user.balance < c.price) {
                      messenger.showSnackBar(const SnackBar(
                          content: Text(
                              'Insufficient balance. Please redeem a code.')));
                      return;
                    }
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Purchase'),
                        content: Text(
                            'Buy "${c.title}" for \$${c.price.toStringAsFixed(2)}?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Confirm')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await prov.purchaseCourse(c);
                      messenger.showSnackBar(SnackBar(
                          content: Text(
                              'You purchased "${c.title}" successfully!')));
                    }
                  },
                  child: Text('\$${c.price.toStringAsFixed(2)}'),
                ),
              );
            },
          ),

          // ── Profile ────────────────────────────────────────
          StudentProfileTab(
            user: user,
            prov: prov,
            newPassCtrl: _newPassCtrl,
            redeemCtrl: _redeemCtrl,
          ),
        ],
      ),
    );
  }
}
