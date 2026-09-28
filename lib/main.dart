import 'package:flutter/material.dart';
import 'package:innvoice_generator/provider/invoice_provider.dart';
import 'package:innvoice_generator/screens/splash.dart';
import 'package:innvoice_generator/widgets/theme.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider()..loadInvoices(),
        ),
      ],
      child: const InvoiceGeneratorApp(),
    ),
  );
}

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoice Generator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}