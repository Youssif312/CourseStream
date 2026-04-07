import 'package:flutter/material.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import 'role_badge.dart';

/// Profile tab for students: change password + redeem code.
class StudentProfileTab extends StatelessWidget {
  final User user;
  final AppProvider prov;
  final TextEditingController newPassCtrl;
  final TextEditingController redeemCtrl;

  const StudentProfileTab({
    super.key,
    required this.user,
    required this.prov,
    required this.newPassCtrl,
    required this.redeemCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.account_circle,
                  color: Colors.indigo, size: 40),
              title: Text(user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  roleBadge(user.role),
                  const SizedBox(height: 4),
                  Text('Balance: \$${user.balance.toStringAsFixed(2)}'),
                ],
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'New Password', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Update Password'),
            onPressed: () async {
              if (newPassCtrl.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await prov.updatePassword(newPassCtrl.text.trim());
              messenger.showSnackBar(const SnackBar(
                  content: Text('Password updated successfully!')));
              newPassCtrl.clear();
            },
          ),
          const SizedBox(height: 30),
          const Text('Redeem Payment Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: redeemCtrl,
            decoration: const InputDecoration(
                labelText: 'Enter payment code',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.redeem),
            label: const Text('Redeem'),
            onPressed: () async {
              final code      = redeemCtrl.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              if (code.isEmpty) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Please enter a code')));
                return;
              }
              final idx = prov.codes.indexWhere((x) => x.code == code);
              if (idx == -1) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Invalid code')));
                return;
              }
              if (prov.codes[idx].used) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('This code has already been used')));
                return;
              }
              final amount = await prov.redeemCode(code);
              if (amount != null) {
                messenger.showSnackBar(SnackBar(
                    content: Text(
                        'Redeemed +\$${amount.toStringAsFixed(2)}')));
                redeemCtrl.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Profile tab for teachers: change password only.
class TeacherProfileTab extends StatelessWidget {
  final User teacher;
  final AppProvider prov;
  final TextEditingController newPassCtrl;

  const TeacherProfileTab({
    super.key,
    required this.teacher,
    required this.prov,
    required this.newPassCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.account_circle,
                  color: Colors.teal, size: 40),
              title: Text(teacher.username,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: roleBadge(teacher.role),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'New Password', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Update Password'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              if (newPassCtrl.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await prov.updatePassword(newPassCtrl.text.trim());
              messenger.showSnackBar(const SnackBar(
                  content: Text('Password updated successfully!')));
              newPassCtrl.clear();
            },
          ),
        ],
      ),
    );
  }
}
