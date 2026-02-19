import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/person.dart';
import '../widgets/person_card.dart';
import 'person_detail_screen.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _searchText = '';
  late Future<List<Person>> _personsFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    setState(() {
      _personsFuture = personProvider.getHomePersons();
    });
    await Provider.of<TransactionProvider>(context, listen: false)
        .loadAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Person>>(
      future: _personsFuture,
      builder: (context, personSnapshot) {
        if (personSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Account Flow')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (personSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Account Flow')),
            body: Center(child: Text('Error: ${personSnapshot.error}')),
          );
        }

        final homePersons = personSnapshot.data ?? [];
        final homePersonIds = homePersons.map((p) => p.id).toSet();

        return Consumer<TransactionProvider>(
          builder: (context, transactionProvider, child) {
            final allTransactions = transactionProvider.transactions;
            final homeTransactions = allTransactions
                .where((tx) => homePersonIds.contains(tx.personId))
                .toList();

            double totalCredit = 0;
            double totalDebit = 0;

            for (var transaction in homeTransactions) {
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

            return Scaffold(
              drawer: AppDrawer(gradientColors: gradientColors),
              body: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(totalBalance, gradientColors, context),
                  _buildSummaryCards(totalCredit, totalDebit),
                  _buildSearchBar(),
                  _buildSectionHeader(context, 'Recent People'),
                  _buildPersonList(homePersons),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showAddPersonDialog(context),
                backgroundColor: gradientColors[0],
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
      double totalBalance, List<Color> gradientColors, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          '₹${totalBalance.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 50.0),
            child: Column(
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSummaryCards(double totalCredit, double totalDebit) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildSummaryCard(
              'You will give',
              '₹${totalCredit.toStringAsFixed(2)}',
              [Colors.green.shade700, Colors.green.shade400],
              Icons.arrow_upward,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'You will get',
              '₹${totalDebit.toStringAsFixed(2)}',
              [Colors.red.shade700, Colors.red.shade400],
              Icons.arrow_downward,
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildSummaryCard(
      String title, String amount, List<Color> colors, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(icon, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
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
    );
  }

  SliverToBoxAdapter _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  SliverList _buildPersonList(List<Person> homePersons) {
    final filteredPersons = homePersons
        .where((person) =>
        person.name.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final person = filteredPersons[index];
          _animationController.forward();
          return FadeTransition(
            opacity: _animationController,
            child: PersonCard(
              person: person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonDetailScreen(person: person),
                  ),
                ).then((_) => _loadData());
              },
              onEdit: () => _showEditPersonDialog(context, person),
              onDelete: () => _showDeleteConfirmationDialog(context, person),
            ),
          );
        },
        childCount: filteredPersons.length,
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Person'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
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
                if (formKey.currentState!.validate()) {
                  final name = nameController.text;
                  final personProvider =
                  Provider.of<PersonProvider>(context, listen: false);
                  final newPerson = Person(
                      name: name, createdAt: DateTime.now(), isCashbook: false);
                  await personProvider.addPerson(newPerson);
                  _loadData();
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
    final nameController = TextEditingController(text: person.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Person'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
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
                if (formKey.currentState!.validate()) {
                  final newName = nameController.text;
                  final personProvider =
                  Provider.of<PersonProvider>(context, listen: false);
                  await personProvider
                      .updatePerson(person.copyWith(name: newName));
                  _loadData();
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
          content: Text(
              'Are you sure you want to delete ${person.name}? This will also delete all their transactions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final personProvider =
                Provider.of<PersonProvider>(context, listen: false);
                final transactionProvider =
                Provider.of<TransactionProvider>(context, listen: false);

                await personProvider.deletePerson(person.id!);
                transactionProvider.removeTransactionsByPersonId(person.id!);

                _loadData();

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
