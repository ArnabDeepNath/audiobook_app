import 'package:flutter/material.dart';
import '../constants/app_content.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppContent.privacyPolicy,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.justify,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
