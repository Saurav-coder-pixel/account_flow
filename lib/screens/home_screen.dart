import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/person.dart';
import '../models/transaction.dart';
import '../widgets/person_card.dart';
import 'add_person_screen.dart';
import 'history_screen.dart';
import 'person_detail_screen.dart';
import 'cashbook_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PersonProvider>(context, listen: false).loadPersons();
      Provider.of<TransactionProvider>(context, listen: false)
          .loadAllTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
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
        final Color balanceColor = isCredit ? Colors.green : Colors.red;
        final List<Color> gradientColors = isCredit
            ? [Colors.green.shade700, Colors.green.shade400]
            : [Colors.red.shade700, Colors.red.shade400];

        return Scaffold(
          appBar: AppBar(
            title: Text('Account Flow', style: TextStyle(color: Colors.white ),),
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
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '₹${totalBalance.toStringAsFixed(2)}',
                        style: TextStyle(
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
                  child: Column(
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
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.book),
                  title: Text('Cashbook'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CashbookScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                ),
                Divider(),
                SwitchListTile(
                  title: Text('Dark Mode'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
                  },
                  secondary: Icon(Icons.dark_mode),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
          body: Column(
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
                              Text(
                                'Total Credit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₹${totalCredit.toStringAsFixed(2)}',
                                style: TextStyle(
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
                    SizedBox(width: 16),
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
                              Text(
                                'Total Debit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₹${totalDebit.toStringAsFixed(2)}',
                                style: TextStyle(
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
              Expanded(
                child: Consumer<PersonProvider>(
                  builder: (context, personProvider, child) {
                    if (personProvider.persons.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No accounts yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap + to add your first account',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: personProvider.persons.length,
                      itemBuilder: (context, index) {
                        final person = personProvider.persons[index];
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
                          onEdit: () => _editPerson(person),
                          onDelete: () => _deletePerson(person),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPersonScreen()),
              );
              if (result == true) {
                Provider.of<PersonProvider>(context, listen: false)
                    .loadPersons();
              }
            },
            child: Icon(Icons.add),
            backgroundColor: balanceColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  void _editPerson(Person person) {
    TextEditingController controller = TextEditingController(text: person.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Account'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final updatedPerson =
                  person.copyWith(name: controller.text);
                  await Provider.of<PersonProvider>(context, listen: false)
                      .updatePerson(updatedPerson);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deletePerson(Person person) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete ${person.name}? This will also delete all transactions for this account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<PersonProvider>(context, listen: false)
                    .deletePerson(person.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account deleted successfully')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
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
          title: Text('About Account Flow'),
          content: Text(
            'Account Flow is a simple khatabook app for managing personal accounts and transactions.\n\nVersion 1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
