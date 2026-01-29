import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ticket', // Ensure AndroidManifest.xml has "Smart Ticket" as well.
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

// -----------------------
// Login Page (No auto-login)
// -----------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _uidController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool rememberMe = false;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }
  
  @override
  void dispose() {
    _uidController.dispose();
    _pinController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRememberedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool storedRememberMe = prefs.getBool('rememberMe') ?? false;
    String? storedUid = prefs.getString('uid');
    String? storedPin = prefs.getString('pin');
    if (storedRememberMe && storedUid != null && storedPin != null) {
      _uidController.text = storedUid;
      _pinController.text = storedPin;
      setState(() {
        rememberMe = true;
      });
    }
  }
  
  Future<void> _saveRememberedCredentials(String uid, String pin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('pin', pin);
    await prefs.setBool('rememberMe', rememberMe);
  }
  
  Future<void> _clearRememberedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('pin');
    await prefs.remove('rememberMe');
  }
  
  Future<void> _attemptLogin() async {
    if (isLoading) return;
    if (_formKey.currentState?.validate() != true) return;
    
    setState(() {
      isLoading = true;
    });
    
    String uid = _uidController.text.trim();
    String pin = _pinController.text.trim();
    
    try {
      // Retrieve the document from 'pins' using the entered PIN as docID.
      DocumentSnapshot<Map<String, dynamic>> pinDoc =
          await FirebaseFirestore.instance.collection('pins').doc(pin).get();
      
      if (!pinDoc.exists) {
        _showError("Invalid PIN");
      } else {
        final data = pinDoc.data();
        if (data != null && data['card'] == uid) {
          if (rememberMe) {
            await _saveRememberedCredentials(uid, pin);
          } else {
            await _clearRememberedCredentials();
          }
          _showMessage("Login successful");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage(uid: uid, loginPin: pin)),
          );
        } else {
          _showError("Invalid credentials");
        }
      }
    } catch (e) {
      _showError("Error during login: $e");
    }
    
    setState(() {
      isLoading = false;
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a gradient background for a sleek feel.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0f7fa), Color(0xFFffffff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Smart Ticket Login",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _uidController,
                        decoration: InputDecoration(
                          labelText: 'User ID',
                          hintText: 'Enter your 8-character UID',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLength: 8,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'User ID is required';
                          }
                          if (value.length > 8) {
                            return 'User ID must be up to 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinController,
                        decoration: InputDecoration(
                          labelText: 'PIN',
                          hintText: 'Enter your 4-digit PIN',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'PIN is required';
                          }
                          if (value.length != 4) {
                            return 'PIN must be exactly 4 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (newValue) {
                              setState(() {
                                rememberMe = newValue ?? false;
                              });
                            },
                          ),
                          const Text("Remember me"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _attemptLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Login', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------
// Dashboard Page
// -----------------------
class DashboardPage extends StatefulWidget {
  final String uid;
  final String loginPin; // Used for confirming toggle actions.
  
  const DashboardPage({required this.uid, required this.loginPin, super.key});
  
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Trigger a rebuild to refresh logs.
  void _refreshLogs() {
    setState(() {});
  }
  
  Future<void> _updateWallet(double newWallet) async {
    try {
      await FirebaseFirestore.instance
          .collection('cards')
          .doc(widget.uid)
          .update({'wallet': newWallet});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wallet updated"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating wallet: $e"), backgroundColor: Colors.red),
      );
    }
  }
  
  void _editWallet(double currentWallet) {
    final _walletEditController = TextEditingController(text: currentWallet.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Wallet"),
        content: TextField(
          controller: _walletEditController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "New Wallet Value"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              double? newWallet = double.tryParse(_walletEditController.text);
              if (newWallet != null) {
                _updateWallet(newWallet);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid wallet value"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
  
  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ticket No: ${log['ticket_no']}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("Type: ${log['type']}", style: const TextStyle(fontSize: 18)),
                Text("Date: ${log['date_time']}", style: const TextStyle(fontSize: 18)),
                Text("Destination: ${log['destination']}", style: const TextStyle(fontSize: 18)),
                Text("Boarding: ${log['boarding']}", style: const TextStyle(fontSize: 18)),
                if (log['type'] == 'Regular')
                  Text("Amount: ₹ ${log['amount']}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _promptPinForToggle(bool currentBlacklist) {
    final _pinConfirmController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Confirm PIN"),
        content: TextField(
          controller: _pinConfirmController,
          decoration: const InputDecoration(
            labelText: "Enter your 4-digit PIN",
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinConfirmController.text.trim() == widget.loginPin) {
                Navigator.pop(context);
                _toggleSmartTag(currentBlacklist);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PIN does not match"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleSmartTag(bool currentValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('cards')
          .doc(widget.uid)
          .update({'blacklist': !currentValue});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating smart tag: $e"), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final cardStream = FirebaseFirestore.instance
        .collection('cards')
        .doc(widget.uid)
        .snapshots();
    final logsStream = FirebaseFirestore.instance
        .collection('cards')
        .doc(widget.uid)
        .collection('logs')
        .orderBy('date_time', descending: true)
        .snapshots();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginPage()));
          },
        ),
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
          )
        ],
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFf0f4f8), Color(0xFFffffff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: cardStream,
          builder: (context, cardSnapshot) {
            if (cardSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!cardSnapshot.hasData || !cardSnapshot.data!.exists) {
              return const Center(child: Text("Card data not found"));
            }
            final cardData = cardSnapshot.data!.data()!;
            double wallet = (cardData['wallet'] is num)
                ? (cardData['wallet'] as num).toDouble()
                : 0.0;
            bool blacklist = cardData['blacklist'] ?? false;
            
            return Column(
              children: [
                GestureDetector(
                  onLongPress: () {
                    _editWallet(wallet);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42a5f5), Color(0xFF64b5f6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      "Wallet: ₹ $wallet",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: logsStream,
                    builder: (context, logsSnapshot) {
                      if (logsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!logsSnapshot.hasData || logsSnapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No logs available"));
                      }
                      final logsDocs = logsSnapshot.data!.docs;
                      return ListView.builder(
                        itemCount: logsDocs.length,
                        itemBuilder: (context, index) {
                          final log = logsDocs[index].data();
                          return RepaintBoundary(
                            child: GestureDetector(
                              onTap: () => _showLogDetails(log),
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text("Ticket No: ${log['ticket_no']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Type: ${log['type']}"),
                                      Text("Date: ${log['date_time']}"),
                                      Text("Destination: ${log['destination']}"),
                                      Text("Boarding: ${log['boarding']}"),
                                      if (log['type'] == 'Regular')
                                        Text("Amount: ₹ ${log['amount']}"),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cards')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }
          bool blacklist = snapshot.data!.data()?['blacklist'] ?? false;
          return AnimatedToggleButton(
            currentBlacklist: blacklist,
            onToggle: () {
              _promptPinForToggle(blacklist);
            },
          );
        },
      ),
    );
  }
}

// -----------------------
// Custom Animated Toggle Button Widget
// -----------------------
class AnimatedToggleButton extends StatelessWidget {
  final bool currentBlacklist;
  final VoidCallback onToggle;
  const AnimatedToggleButton({
    required this.currentBlacklist,
    required this.onToggle,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isActive = !currentBlacklist;
    final label = isActive ? "Smart Tag: ON" : "Smart Tag: OFF";
    final bgColor = isActive ? Colors.green : Colors.red;
    final iconData = isActive ? Icons.toggle_on : Icons.toggle_off;
    
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                iconData,
                key: ValueKey<bool>(isActive),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                label,
                key: ValueKey<String>(label),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
