import 'package:flutter/material.dart';
import '../models/person.dart';
import '../helpers/database_helper.dart';

class PersonProvider with ChangeNotifier {

  Future<void> refreshPersonBalance(String personId) async{
    print('Attempting to refresh balance for person ID: $personId');
  }
  
  List<Person> _persons = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Person> get persons => _persons;

  Future<void> loadPersons() async {
    _persons = await _dbHelper.getAllPersons();
    notifyListeners();
  }

  Future<void> addPerson(String name) async {
    final person = Person(
      name: name,
      createdAt: DateTime.now(),
    );
    final id = await _dbHelper.insertPerson(person);
    final newPerson = person.copyWith(id: id);
    _persons.add(newPerson);
    notifyListeners();
  }

  Future<void> updatePerson(Person person) async {
    await _dbHelper.updatePerson(person);
    final index = _persons.indexWhere((p) => p.id == person.id);
    if (index != -1) {
      _persons[index] = person;
      notifyListeners();
    }
  }

  Future<void> deletePerson(int personId) async {
    await _dbHelper.deletePerson(personId);
    _persons.removeWhere((person) => person.id == personId);
    notifyListeners();
  }

  Future<Person?> getPersonById(int id) async {
    return await _dbHelper.getPersonById(id);
  }

  Future<double> getPersonBalance(int personId) async {
    return await _dbHelper.getPersonBalance(personId);
  }
}