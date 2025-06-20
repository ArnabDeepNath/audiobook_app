import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/book_provider.dart';
import '../providers/language_provider.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    _nameController =
        TextEditingController(text: bookProvider.user?.name ?? '');
    _emailController =
        TextEditingController(text: bookProvider.user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showDeleteAccountConfirmation(
      BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lang.translate('deleteAccount')),
          content: Text(lang.translate('deleteAccountConfirmation')),
          actions: <Widget>[
            TextButton(
              child: Text(lang.translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                lang.translate('delete'),
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                _launchDeleteAccountPage();
              },
            ),
          ],
        );
      },
    );
  }

  void _launchDeleteAccountPage() async {
    const String url =
        'https://granthakatha.com/pdoapp/public/delete_account.html';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open delete account page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final bookProvider = Provider.of<BookProvider>(context);

    if (!bookProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(lang.translate('profile')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lang.translate('loginRequired'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(lang.translate('login')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: lang.translate('name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang.translate('nameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: lang.translate('email'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang.translate('emailRequired');
                  }
                  if (!value.contains('@')) {
                    return lang.translate('invalidEmail');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await bookProvider.updateUserProfile(
                        _nameController.text,
                        _emailController.text,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(lang.translate('profileUpdated')),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(lang.translate('updateFailed')),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(lang.translate('updateProfile')),
              ),
              const SizedBox(height: 48),
              Divider(),
              const SizedBox(height: 16),
              Text(
                lang.translate('accountSettings'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: Icon(Icons.delete_forever, color: Colors.red[700]),
                label: Text(
                  lang.translate('deleteAccount'),
                  style: TextStyle(color: Colors.red[700]),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red[300]!),
                ),
                onPressed: () => _showDeleteAccountConfirmation(context, lang),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
