import 'package:flutter/material.dart';
import '../models/user.dart';

Widget roleBadge(UserRole role) {
  final (label, color) = switch (role) {
    UserRole.admin   => ('Admin',   Colors.red),
    UserRole.teacher => ('Teacher', Colors.teal),
    UserRole.student => ('Student', Colors.indigo),
  };
  return Chip(
    label: Text(label,
        style: const TextStyle(color: Colors.white, fontSize: 11)),
    backgroundColor: color,
    padding: EdgeInsets.zero,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
