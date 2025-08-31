import 'package:flutter/material.dart';
import '../models/person.dart';
import '../helpers/database_helper.dart';

class PersonProvider with ChangeNotifier {

  Future<void> refreshPersonBalance(int personId) async{
    notifyListeners();
  }

  List<Person> _persons = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Person> get persons => _persons;

  Future<void> loadPersons() async {
    _persons = await _dbHelper.getAllPersons();
    notifyListeners();
  }

  Future<Person> addPerson(Person person) async {
    final id = await _dbHelper.insertPerson(person);
    final newPerson = person.copyWith(id: id);
    _persons.add(newPerson);
    notifyListeners();
    return newPerson;
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

  Future<Person?> findPersonByName(String name) async {
    try {
      return _persons.firstWhere((person) => person.name == name);
    } catch (e) {
      return null;
    }
  }
}
