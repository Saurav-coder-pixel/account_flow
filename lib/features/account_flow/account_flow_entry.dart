import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './providers/person_provider.dart';
import './providers/transaction_provider.dart';
import './providers/currency_provider.dart';
import './screens/home_screen.dart';
import './screens/currency_selection_screen.dart';

/// Entry point for the Account Flow feature.
/// Wraps the sub-tree in its own providers so they are scoped to this tool only.
class AccountFlowEntry extends StatefulWidget {
  const AccountFlowEntry({super.key});

  @override
  State<AccountFlowEntry> createState() => _AccountFlowEntryState();
}

class _AccountFlowEntryState extends State<AccountFlowEntry> {
  bool _loading = true;
  bool _currencySelected = false;
  late CurrencyProvider _currencyProvider;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currencyProvider = CurrencyProvider();
    await _currencyProvider.loadCurrency();
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getBool('isCurrencySelected') ?? false;
    if (mounted) {
      setState(() {
        _currencySelected = selected;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PersonProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider.value(value: _currencyProvider),
      ],
      child: _AccountFlowNavigator(currencySelected: _currencySelected),
    );
  }
}

class _AccountFlowNavigator extends StatefulWidget {
  final bool currencySelected;
  const _AccountFlowNavigator({required this.currencySelected});

  @override
  State<_AccountFlowNavigator> createState() => _AccountFlowNavigatorState();
}

class _AccountFlowNavigatorState extends State<_AccountFlowNavigator> {
  @override
  void initState() {
    super.initState();
    // Pre-load data after providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    await Future.wait([
      personProvider.loadPersons(),
      transactionProvider.loadAllTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currencySelected) {
      return const CurrencySelectionScreen();
    }
    return const HomeScreen();
  }
}
