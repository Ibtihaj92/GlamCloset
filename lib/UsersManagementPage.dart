import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersManagementPage extends StatefulWidget {

  @override
  _UsersManagementPageState createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');
  List<Map<String, String>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() {
    // Query only users with userType = "user"
    _dbRef.orderByChild('userType').equalTo('user').onValue.listen((event) {
      final data = event.snapshot.value;
      final List<Map<String, String>> loadedUsers = [];

      if (data != null && data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            loadedUsers.add({
              "email": value['email']?.toString() ?? '',
              "phone": value['phone']?.toString() ?? '',
              "id": key,
            });
          }
        });
      }

      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    });

  }

  void deleteUser(String userId) async {
    await _dbRef.child(userId).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users Management"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? Center(
        child: Text(
          "No users available",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Icon(Icons.person, color: Colors.deepPurple),
              ),
              title: Text(
                user["email"]!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                user["phone"]!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => deleteUser(user["id"]!),
              ),
            ),
          );
        },
      ),
    );
  }
}
