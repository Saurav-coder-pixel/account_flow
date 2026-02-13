import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import '../models/person.dart';
import '../widgets/person_card.dart';
import 'history_screen.dart';
import 'cashbook_screen.dart';
import 'split_expense_screen.dart';
import 'person_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false)
          .loadAllTransactions();
      Provider.of<PersonProvider>(context, listen: false).loadPersons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Consumer2<TransactionProvider, PersonProvider>(
      builder: (context, transactionProvider, personProvider, child) {
        final allTransactions = transactionProvider.transactions;
        double totalCredit = 0;
        double totalDebit = 0;

        for (var transaction in allTransactions) {
          if (transaction.type == TransactionType.credit) {
            totalCredit += transaction.amount;
          } else {
            totalDebit += transaction.amount;
          }
        }

        final totalBalance = totalCredit - totalDebit;
        final bool isCredit = totalBalance >= 0;
        final List<Color> gradientColors = isCredit
            ? [Colors.green.shade700, Colors.green.shade400]
            : [Colors.red.shade700, Colors.red.shade400];

        final filteredPersons = personProvider.persons.where((person) {
          return person.name.toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Account Flow', style: TextStyle(color: Colors.white),),
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '₹${totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Account Flow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.book),
                  title: const Text('Cashbook'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CashbookScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.call_split),
                  title: const Text('Split Expense'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SplitExpenseScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
                  },
                  secondary: const Icon(Icons.dark_mode),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.green.shade700,
                              Colors.green.shade400
                            ]),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Total Credit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${totalCredit.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.red.shade700,
                              Colors.red.shade400
                            ]),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Total Debit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${totalDebit.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search People...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recent People',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: filteredPersons.isEmpty
                    ? const Center(
                  child: Text('No people added yet.'),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPersons.length,
                  itemBuilder: (context, index) {
                    final person = filteredPersons[index];
                    return PersonCard(
                      person: person,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PersonDetailScreen(person: person),
                          ),
                        );
                      },
                      onEdit: () => _showEditPersonDialog(context, person),
                      onDelete: () => _showDeleteConfirmationDialog(
                          context, person),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddPersonDialog(context),
            backgroundColor: gradientColors[0],
            child: const Icon(Icons.add, color: Colors.white,),
          ),
        );
      },
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Person'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final name = _nameController.text;
                  final personProvider =
                  Provider.of<PersonProvider>(context, listen: false);
                  final newPerson = Person(name: name, createdAt: DateTime.now());
                  await personProvider.addPerson(newPerson);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    final _nameController = TextEditingController(text: person.name);
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Person'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newName = _nameController.text;
                  final personProvider =
                  Provider.of<PersonProvider>(context, listen: false);
                  await personProvider
                      .updatePerson(person.copyWith(name: newName));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Person'),
          content: Text('Are you sure you want to delete ${person.name}? This will also delete all their transactions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final personProvider =
                Provider.of<PersonProvider>(context, listen: false);
                final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                
                // 1. Delete person from DB and PersonProvider
                await personProvider.deletePerson(person.id!);
                
                // 2. Sync TransactionProvider to remove transactions and update global totals
                transactionProvider.removeTransactionsByPersonId(person.id!);
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About Account Flow'),
          content: const Text(
            'Account Flow is a simple khatabook app for managing personal accounts and transactions.\n\nVersion 1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
