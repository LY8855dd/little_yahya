import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/commitment_screen.dart';
import 'screens/food_screen.dart';
import 'screens/hobbies_screen.dart';
import 'screens/money_screen.dart';
import 'screens/today_screen.dart';
import 'services/app_state.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  runApp(LittleYahyaApp(storage: storage));
}

class LittleYahyaApp extends StatelessWidget {
  final StorageService storage;
  const LittleYahyaApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(storage),
      child: MaterialApp(
        title: 'Little Yahya',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const RootShell(),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    TodayScreen(),
    CommitmentScreen(),
    FoodScreen(),
    MoneyScreen(),
    HobbiesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Commitment'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), label: 'Food'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), label: 'Money'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'Hobbies'),
        ],
      ),
    );
  }
}
