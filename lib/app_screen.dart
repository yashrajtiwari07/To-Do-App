import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'login_page.dart';
// import 'privacy_policy_screen.dart';

class AppScreen extends StatefulWidget {
  @override
  _AppScreenState createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> filteredTodos = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUser();
    _searchController.addListener(_filterTodos);
  }

  void _getUser() {
    setState(() {
      _user = _auth.currentUser;
      if (_user != null) {
        _loadTodos();
      }
    });
  }

  void _filterTodos() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredTodos = todos.where((todo) {
        return todo['text'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleDone(int index) {
    setState(() {
      todos[index]['done'] = !todos[index]['done'];
      _filterTodos();
      _saveTodos();
    });
  }

  void _deleteTodoConfirm(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to delete this TODO?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                setState(() {
                  todos.removeAt(index);
                  _filterTodos();
                  _saveTodos();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addTodoItem() {
    TextEditingController _textFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a new todo item'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Add a new todo item"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                if (_textFieldController.text.isNotEmpty) {
                  setState(() {
                    todos.add({'text': _textFieldController.text, 'done': false});
                    _filterTodos();
                    _saveTodos();
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : AssetImage('assets/images/alice.jpeg') as ImageProvider,
                radius: 40,
              ),
              SizedBox(height: 16),
              Text(_user?.displayName ?? 'User Name'),
              Text(_user?.email ?? 'user@example.com'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // void _openPrivacyPolicyScreen() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
  //   );
  // }

  void _showRateUsDialog() {
    int _rating = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Rate Us'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  if (_rating > 0)
                    Text(
                      _rating == 1
                          ? 'Bad 😞'
                          : _rating == 2
                          ? 'Average 😐'
                          : _rating == 3
                          ? 'Good 🙂'
                          : _rating == 4
                          ? 'Excellent 😃'
                          : 'Outstanding 🌟',
                      style: TextStyle(fontSize: 18),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Remind Me Later'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Rate Now'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (_rating > 0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Thanks for rating us!'),
                            actions: [
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Please rate us first!'),
                            actions: [
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _loadTodos() async {
    if (_user == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? todosString = prefs.getString('todos_${_user!.uid}');
    if (todosString != null) {
      List<dynamic> decodedTodos = jsonDecode(todosString);
      setState(() {
        todos = decodedTodos.map((todo) => Map<String, dynamic>.from(todo)).toList();
        _filterTodos();
      });
    } else {
      setState(() {
        todos = [
          {'text': 'Go to College ', 'done': false},
          {'text': 'Gym Time', 'done': false},
          {'text': 'Do Homework', 'done': false},
          {'text': 'Attend Cipher School Class', 'done': false},
          {'text': 'make Dinner', 'done': true},
          {'text': 'clean pool', 'done': true},
        ];
        _filterTodos();
      });
    }
  }

  void _saveTodos() async {
    if (_user == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String todosString = jsonEncode(todos);
    await prefs.setString('todos_${_user!.uid}', todosString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo ~ App'),
        centerTitle: true,
        backgroundColor: Colors.yellowAccent,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _showProfile,
              child: CircleAvatar(
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : AssetImage('assets/images/alice.jpeg') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_user?.displayName ?? 'User Name'),
              accountEmail: Text(_user?.email ?? 'user@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : AssetImage('assets/images/alice.jpeg') as ImageProvider,
              ),
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
              ),
            ),
            // ListTile(
            //   splashColor: Colors.teal,
            //   leading: Icon(Icons.privacy_tip),
            //   title: Text('Privacy Policy'),
            //   onTap: _openPrivacyPolicyScreen,
            // ),
            ListTile(
              splashColor: Colors.teal,
              leading: Icon(Icons.rate_review),
              title: Text('Rate Us'),
              onTap: _showRateUsDialog,
            ),
            Spacer(),
            ListTile(
              splashColor: Colors.yellowAccent,
              leading: Icon(Icons.logout, color: Colors.yellowAccent),
              title: Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'All ToDos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTodos.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Checkbox(
                        value: filteredTodos[index]['done'],
                        onChanged: (value) {
                          _toggleDone(index);
                        },
                      ),
                      title: Text(
                        filteredTodos[index]['text'],
                        style: TextStyle(
                          decoration: filteredTodos[index]['done']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.deepPurple),
                        onPressed: () {
                          _deleteTodoConfirm(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodoItem,
        child: Icon(Icons.add,
          size: 37,

        ),
        backgroundColor: Colors.yellow,
      ),
    );
  }
}
