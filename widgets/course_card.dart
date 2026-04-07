import 'package:flutter/material.dart';
import '../models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final Widget trailing;

  const CourseCard({super.key, required this.course, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill, color: Colors.indigo),
        title: Text(course.title),
        subtitle: Text(course.description),
        trailing: trailing,
      ),
    );
  }
}
