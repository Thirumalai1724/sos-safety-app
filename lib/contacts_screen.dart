import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsService {
  static Future<void> saveContacts(String appa, String amma, String brother) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emergency_contacts', [appa, amma, brother]);
  }

  static Future<List<String>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('emergency_contacts') ?? ['', '', ''];
  }
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _appaController = TextEditingController();
  final _ammaController = TextEditingController();
  final _brotherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactsService.getContacts();
    setState(() {
      _appaController.text = contacts[0];
      _ammaController.text = contacts[1];
      _brotherController.text = contacts[2];
    });
  }

  Future<void> _saveContacts() async {
    await ContactsService.saveContacts(
      _appaController.text.trim(),
      _ammaController.text.trim(),
      _brotherController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contacts saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _appaController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Appa Number',
                hintText: '+91XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ammaController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Amma Number',
                hintText: '+91XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brotherController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Brother Number',
                hintText: '+91XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveContacts,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                child: Text('Save Contacts'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}