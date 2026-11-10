import 'package:flutter/material.dart';
import '../services/isar_service.dart';
import '../services/profile_service.dart';
import 'home_screen.dart';

class NameInputScreen extends StatefulWidget {
  final IsarService isarService;
  final ProfileService profile;
  const NameInputScreen({
    super.key,
    required this.isarService,
    required this.profile,
  });
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_name.text.trim().isEmpty || _busy) return;
    setState(() {
      _busy = true;
    });
    try {
      await widget.profile.onboard(_name.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(
            isarService: widget.isarService,
            profile: widget.profile,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo_blocklab.png',
                    width: 112,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'A little shape.\nA big idea.',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Build something that is yours.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _name,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _start(),
                  decoration: const InputDecoration(
                    labelText: 'What should we call you?',
                    hintText: 'Your name',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _name.text.trim().isEmpty || _busy ? null : _start,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(_busy ? 'Getting ready…' : 'Let’s build'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
