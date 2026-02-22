import 'package:account_flow/providers/currency_provider.dart';
import 'package:account_flow/screens/currency_selection_screen.dart';
import 'package:account_flow/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/person_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final currencyProvider = CurrencyProvider();
  await currencyProvider.loadCurrency();
  runApp(MyApp(currencyProvider: currencyProvider));
}

class MyApp extends StatelessWidget {
  final CurrencyProvider currencyProvider;
  const MyApp({super.key, required this.currencyProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PersonProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: currencyProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Account Flow',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: Colors.blue,
            ),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              HomeScreen.routeName: (ctx) => const HomeScreen(),
              CurrencySelectionScreen.routeName: (ctx) =>
                  CurrencySelectionScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
