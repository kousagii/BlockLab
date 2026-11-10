import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'design/app_theme.dart';
import 'models/isar_models.dart';
import 'screens/home_screen.dart';
import 'screens/name_input_screen.dart';
import 'services/appearance_controller.dart';
import 'services/isar_service.dart';
import 'services/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Nunito',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final preferences = await SharedPreferences.getInstance();
  runApp(
    BlockLabApp(
      profile: ProfileService(preferences),
      appearance: AppearanceController(preferences),
    ),
  );
}

class BlockLabApp extends StatefulWidget {
  final ProfileService profile;
  final AppearanceController appearance;
  const BlockLabApp({
    super.key,
    required this.profile,
    required this.appearance,
  });
  @override
  State<BlockLabApp> createState() => _BlockLabAppState();
}

class _BlockLabAppState extends State<BlockLabApp> {
  late Future<IsarService> _ready;
  @override
  void initState() {
    super.initState();
    _ready = _initialize();
  }

  Future<IsarService> _initialize() async {
    final store = IsarService();
    final db = await store.db;
    final progress = await db.userProgress.where().findFirst();
    const legacy = {
      'The Basics': 'basics',
      'Lesson 2': 'dimensions',
      'Lesson 3': 'house',
    };
    if (progress != null) {
      for (final name in progress.finishedLessonNames) {
        if (legacy.containsKey(name)) {
          await widget.profile.completeLesson(legacy[name]!);
        }
      }
    }
    return store;
  }

  @override
  Widget build(BuildContext context) => AppearanceScope(
    controller: widget.appearance,
    child: ListenableBuilder(
      listenable: widget.appearance,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BlockLab',
        themeMode: widget.appearance.mode,
        theme: AppTheme.build(Brightness.light),
        darkTheme: AppTheme.build(Brightness.dark),
        home: FutureBuilder<IsarService>(
          future: _ready,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not open your works: ${snapshot.error}'),
                        TextButton(
                          onPressed: () => setState(() {
                            _ready = _initialize();
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar_rounded, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'BlockLab',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              );
            }
            return widget.profile.accepted && widget.profile.name != null
                ? HomeScreen(
                    isarService: snapshot.data!,
                    profile: widget.profile,
                  )
                : NameInputScreen(
                    isarService: snapshot.data!,
                    profile: widget.profile,
                  );
          },
        ),
      ),
    ),
  );
}
