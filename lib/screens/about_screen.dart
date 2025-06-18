import 'package:flutter/material.dart';
import 'package:grantha_katha/constants/app_content.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('about')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/logo_transparent.png',
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              'Grantha Katha',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              AppContent.aboutUs,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(lang.translate('privacyPolicy')),
              onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(lang.translate('terms')),
              onTap: () => Navigator.pushNamed(context, '/terms'),
            ),
          ],
        ),
      ),
    );
  }
}
