import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final box = Hive.box('settings');

  final nameController = TextEditingController();
  final taxController = TextEditingController();
  final currencyController = TextEditingController();
  final prefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = box.get('companyName', defaultValue: '');
    taxController.text = box.get('tax', defaultValue: '0');
    currencyController.text = box.get('currency', defaultValue: '\$');
    prefixController.text = box.get('prefix', defaultValue: 'INV-');
  }

  void saveSettings() {
    box.put('companyName', nameController.text);
    box.put('tax', taxController.text);
    box.put('currency', currencyController.text);
    box.put('prefix', prefixController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings Saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      floatingActionButton: FloatingActionButton(
        onPressed: saveSettings,
        child: const Icon(Icons.save),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Company Name"),
            ),

            TextField(
              controller: taxController,
              decoration:
                  const InputDecoration(labelText: "Default Tax (%)"),
              keyboardType: TextInputType.number,
            ),

            TextField(
              controller: currencyController,
              decoration:
                  const InputDecoration(labelText: "Currency Symbol"),
            ),

            TextField(
              controller: prefixController,
              decoration:
                  const InputDecoration(labelText: "Invoice Prefix"),
            ),
          ],
        ),
      ),
    );
  }
}