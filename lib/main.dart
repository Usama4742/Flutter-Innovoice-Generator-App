import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:innvoice_generator/data/views/screens/dashboard/dashboard_screen.dart';
import 'package:innvoice_generator/providers/invoice_provider.dart';
import 'package:provider/provider.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('invoices');
  await Hive.openBox('settings');

  runApp(const InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return
     MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoiceViewModel()),
      ],
      child:
       MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Invoice Generator",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}