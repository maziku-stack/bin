import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:esportapp/authenticate/login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final nameController = TextEditingController();
  File? _profileImage;

  Future<void> _pickProfileImageFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });

      // Optionally update user's photoURL if you're storing this in Firebase Storage
      // For now, we’re only using it locally
    }
  }

  Future<void> _updateDisplayName() async {
    final name = nameController.text.trim();
    if (name.isNotEmpty) {
      await user?.updateDisplayName(name);
      await user?.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name updated successfully")),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (user?.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    nameController.text = user?.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
    ? FileImage(_profileImage!)
    : const AssetImage('assets/default_avatar.png'),

                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _pickProfileImageFromGallery,
                  tooltip: "Pick from Gallery",
                  
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 5),
          ElevatedButton.icon(
            onPressed: _updateDisplayName,
            icon: const Icon(Icons.save),
            label: const Text("Save Name"),
          ),
          const Divider(height: 15),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Color.fromARGB(255, 138, 190, 230)),
            title: const Text("Reset Password"),
            onTap: _resetPassword,
          ),
          const Divider(height: 10),
          ListTile(
            leading: const Icon(Icons.logout, color: Color.fromRGBO(120, 149, 251, 1)),
            title: const Text("Logout"),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}
