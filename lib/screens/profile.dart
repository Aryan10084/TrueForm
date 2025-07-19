import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/string_extensions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? gender;
  String? height;
  String? weight;
  String? goal;
  File? profileImage;
  late String email;
  late String name;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      gender = prefs.getString('gender') ?? 'Male';
      height = prefs.getString('height') ?? "5'5'' (165 cm)";
      weight = prefs.getString('weight') ?? '65–70 kg';
      goal = prefs.getString('goal') ?? 'Slim';
      final imgPath = prefs.getString('profileImage');
      if (imgPath != null) profileImage = File(imgPath);
      final user = FirebaseAuth.instance.currentUser;
      email = user?.email ?? 'user@email.com';
      name = email.split('@').first.split('.').first.capitalize();
    });
  }

  Future<void> _editField(String field, String label, String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(field, result);
      setState(() {
        if (field == 'gender') gender = result;
        if (field == 'height') height = result;
        if (field == 'weight') weight = result;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', picked.path);
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  Future<void> _selectGoal(String selected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goal', selected);
    setState(() {
      goal = selected;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/Layer_1.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Color(0xFF2196F3)),
                          onPressed: () {},
                        ),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.055,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.1),
                      ],
                    ),
                  ),
                  // Avatar with edit button
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.18,
                        backgroundColor: const Color(0xFF2196F3),
                        child: profileImage != null
                            ? CircleAvatar(
                                radius: screenWidth * 0.168,
                                backgroundImage: FileImage(profileImage!),
                              )
                            : CircleAvatar(
                                radius: screenWidth * 0.168,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person, size: screenWidth * 0.24, color: Color(0xFF2196F3)),
                              ),
                      ),
                      Positioned(
                        bottom: screenWidth * 0.025,
                        right: screenWidth * 0.025,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(screenWidth * 0.025),
                            child: Icon(Icons.edit, color: Colors.white, size: screenWidth * 0.055),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Hello, ${name.capitalize()}!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.052, color: Colors.black),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    email,
                    style: TextStyle(color: Color(0xFF2196F3), fontSize: screenWidth * 0.038),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Divider(thickness: 1, indent: screenWidth * 0.08, endIndent: screenWidth * 0.08),
                  SizedBox(height: screenHeight * 0.02),
                  // Gender, Height, Weight
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _editField('gender', 'Gender', gender ?? ''),
                          child: _ProfileChip(
                            iconAsset: 'assets/gender_icon.png',
                            label: 'Gender',
                            value: gender ?? '',
                            iconSize: screenWidth * 0.07,
                            avatarRadius: screenWidth * 0.09,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _editField('height', 'Height', height ?? ''),
                          child: _ProfileChip(
                            iconAsset: 'assets/height_icon.png',
                            label: 'Height',
                            value: height ?? '',
                            iconSize: screenWidth * 0.07,
                            avatarRadius: screenWidth * 0.09,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _editField('weight', 'Weight', weight ?? ''),
                          child: _ProfileChip(
                            iconAsset: 'assets/weight_icon.png',
                            label: 'Weight',
                            value: weight ?? '',
                            iconSize: screenWidth * 0.07,
                            avatarRadius: screenWidth * 0.09,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // Goal card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      padding: EdgeInsets.all(screenWidth * 0.045),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.055, // Larger and bold
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Row(
                            children: [
                              // Goal options (left)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _GoalOption(
                                            label: 'Slim',
                                            selected: goal == 'Slim',
                                            onTap: () => _selectGoal('Slim'),
                                            fontSize: screenWidth * 0.045,
                                            boxHeight: screenHeight * 0.055,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.025),
                                        Expanded(
                                          child: _GoalOption(
                                            label: 'Bulk',
                                            selected: goal == 'Bulk',
                                            onTap: () => _selectGoal('Bulk'),
                                            fontSize: screenWidth * 0.045,
                                            boxHeight: screenHeight * 0.055,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.025),
                                        Expanded(
                                          child: _GoalOption(
                                            label: 'Fit',
                                            selected: goal == 'Fit',
                                            onTap: () => _selectGoal('Fit'),
                                            fontSize: screenWidth * 0.045,
                                            boxHeight: screenHeight * 0.055,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Goal illustration (right, no background)
                              SizedBox(
                                width: screenWidth * 0.4,
                                height: screenHeight * 0.3,
                                child: Image.asset('assets/Goal _object.png', fit: BoxFit.contain),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  // Logout button at the bottom
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.08,
                      right: screenWidth * 0.08,
                      bottom: screenHeight * 0.04,
                      top: screenHeight * 0.01,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          'Logout Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                        onPressed: _logout,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final dynamic iconAsset;
  final String label;
  final String value;
  final double? iconSize;
  final double? avatarRadius;
  final double? fontSize;
  const _ProfileChip({required this.iconAsset, required this.label, required this.value, this.iconSize, this.avatarRadius, this.fontSize, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFF101828),
          radius: avatarRadius ?? 28,
          child: iconAsset is IconData
              ? Icon(iconAsset, size: iconSize ?? 28, color: const Color(0xFF2196F3))
              : Image.asset(iconAsset, width: iconSize ?? 28, height: iconSize ?? 28),
        ),
        SizedBox(height: (fontSize ?? 13) * 0.45),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize ?? 15)),
        Text(value, style: TextStyle(color: Colors.black54, fontSize: (fontSize ?? 13) * 0.95)),
      ],
    );
  }
}

class _GoalOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double? boxHeight;
  const _GoalOption({required this.label, required this.selected, required this.onTap, this.fontSize, this.padding, this.boxHeight, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: boxHeight,
        alignment: Alignment.center,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF2196F3) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
} 