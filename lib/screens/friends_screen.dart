import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _surface2 = Color(0xFF1C2333);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _green = Color(0xFF4ADE80);

  final _searchController = TextEditingController();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  Map<String, dynamic>? _searchResult;

  bool _isLoadingFriends = true;
  bool _isSearching = false;
  bool _isSendingRequest = false;
  String? _searchError;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadFriends(), _loadRequests(), _loadSentRequests()]);
    if (mounted) setState(() => _isLoadingFriends = false);
  }

  Future<void> _loadFriends() async {
    final snap = await _db.collection('users').doc(_uid).collection('friends').get();
    _friends = snap.docs.map((d) => d.data()).toList();
  }

  Future<void> _loadRequests() async {
    final snap = await _db.collection('users').doc(_uid).collection('friendRequests').get();
    _incomingRequests = snap.docs.map((d) => d.data()).toList();
  }

  Future<void> _loadSentRequests() async {
    final snap = await _db.collection('users').doc(_uid).collection('sentRequests').get();
    _sentRequests = snap.docs.map((d) => d.data()).toList();
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() { _isSearching = true; _searchResult = null; _searchError = null; });

    try {
      // Search by username
      final usernameDoc = await _db.collection('usernames').doc(query).get();
      if (!usernameDoc.exists) {
        // Try by email
        final emailSnap = await _db.collection('users').where('email', isEqualTo: _searchController.text.trim()).get();
        if (emailSnap.docs.isEmpty) {
          setState(() { _searchError = 'No user found with that username or email.'; _isSearching = false; });
          return;
        }
        setState(() { _searchResult = emailSnap.docs.first.data(); _isSearching = false; });
        return;
      }

      final uid = usernameDoc.data()!['uid'];
      if (uid == _uid) {
        setState(() { _searchError = 'That\'s you! Search for someone else.'; _isSearching = false; });
        return;
      }

      final userDoc = await _db.collection('users').doc(uid).get();
      setState(() { _searchResult = userDoc.data(); _isSearching = false; });
    } catch (e) {
      setState(() { _searchError = 'Something went wrong. Try again.'; _isSearching = false; });
    }
  }

  Future<void> _sendRequest(Map<String, dynamic> user) async {
    setState(() => _isSendingRequest = true);
    final toUid = user['uid'];
    final myDoc = await _db.collection('users').doc(_uid).get();
    final me = myDoc.data()!;

    await Future.wait([
      // Add to their incoming requests
      _db.collection('users').doc(toUid).collection('friendRequests').doc(_uid).set({
        'uid': _uid,
        'username': me['username'] ?? me['email'],
        'email': me['email'],
        'sentAt': FieldValue.serverTimestamp(),
      }),
      // Add to my sent requests
      _db.collection('users').doc(_uid).collection('sentRequests').doc(toUid).set({
        'uid': toUid,
        'username': user['username'] ?? user['email'],
        'email': user['email'],
        'sentAt': FieldValue.serverTimestamp(),
      }),
    ]);

    await _loadSentRequests();
    setState(() { _isSendingRequest = false; _searchResult = null; _searchController.clear(); });
    _showSnack('Friend request sent!', _green);
  }

  Future<void> _acceptRequest(Map<String, dynamic> requester) async {
    final fromUid = requester['uid'];
    final myDoc = await _db.collection('users').doc(_uid).get();
    final me = myDoc.data()!;

    await Future.wait([
      // Add to each other's friends
      _db.collection('users').doc(_uid).collection('friends').doc(fromUid).set({
        'uid': fromUid,
        'username': requester['username'] ?? requester['email'],
        'email': requester['email'],
        'addedAt': FieldValue.serverTimestamp(),
      }),
      _db.collection('users').doc(fromUid).collection('friends').doc(_uid).set({
        'uid': _uid,
        'username': me['username'] ?? me['email'],
        'email': me['email'],
        'addedAt': FieldValue.serverTimestamp(),
      }),
      // Remove request from both sides
      _db.collection('users').doc(_uid).collection('friendRequests').doc(fromUid).delete(),
      _db.collection('users').doc(fromUid).collection('sentRequests').doc(_uid).delete(),
    ]);

    await _loadAll();
    setState(() {});
    _showSnack('You are now friends with ${requester['username'] ?? requester['email']}!', _green);
  }

  Future<void> _declineRequest(String fromUid) async {
    await Future.wait([
      _db.collection('users').doc(_uid).collection('friendRequests').doc(fromUid).delete(),
      _db.collection('users').doc(fromUid).collection('sentRequests').doc(_uid).delete(),
    ]);
    await _loadRequests();
    setState(() {});
  }

  Future<void> _removeFriend(String friendUid) async {
    await Future.wait([
      _db.collection('users').doc(_uid).collection('friends').doc(friendUid).delete(),
      _db.collection('users').doc(friendUid).collection('friends').doc(_uid).delete(),
    ]);
    await _loadFriends();
    setState(() {});
    _showSnack('Friend removed', _textSecondary);
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: _textPrimary)),
      backgroundColor: color.withOpacity(0.2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  bool _alreadyFriend(String uid) => _friends.any((f) => f['uid'] == uid);
  bool _alreadySent(String uid) => _sentRequests.any((r) => r['uid'] == uid);

  List<Map<String, dynamic>> get filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends.where((f) =>
      (f['username'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (f['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _textSecondary, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: _accent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Friends', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border),
          ),
        ),
        body: _isLoadingFriends
            ? Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchSection(),
                        if (_incomingRequests.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _buildIncomingRequests(),
                        ],
                        const SizedBox(height: 28),
                        _buildFriendsList(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('FIND FRIENDS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by username or email...',
                  hintStyle: TextStyle(color: _textSecondary.withOpacity(0.4), fontSize: 13),
                  filled: true,
                  fillColor: _surface,
                  prefixIcon: const Icon(Icons.search, color: _textSecondary, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _searchUser(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSearching
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _bg, strokeWidth: 2))
                    : const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),

        // Search error
        if (_searchError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_searchError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
              ],
            ),
          ),
        ],

        // Search result
        if (_searchResult != null) ...[
          const SizedBox(height: 12),
          _buildSearchResultCard(_searchResult!),
        ],
      ],
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> user) {
    final uid = user['uid'];
    final username = user['username'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final isFriend = _alreadyFriend(uid);
    final requestSent = _alreadySent(uid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          _avatar(username, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(email, style: const TextStyle(color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (isFriend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.3)),
              ),
              child: const Text('Friends ✓', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else if (requestSent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _textSecondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: const Text('Requested', style: TextStyle(color: _textSecondary, fontSize: 12)),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSendingRequest ? null : () => _sendRequest(user),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('FRIEND REQUESTS'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_incomingRequests.length}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._incomingRequests.map((req) => _buildRequestCard(req)),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final username = req['username'] ?? req['email'] ?? 'Unknown';
    final email = req['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _avatar(username, size: 40, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(email, style: const TextStyle(color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Decline
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
            onPressed: () => _declineRequest(req['uid']),
            tooltip: 'Decline',
          ),
          const SizedBox(width: 4),
          // Accept
          ElevatedButton(
            onPressed: () => _acceptRequest(req),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('MY FRIENDS'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_friends.length}', style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_friends.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextField(
            style: const TextStyle(color: _textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Filter friends...',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.4), fontSize: 13),
              filled: true,
              fillColor: _surface,
              prefixIcon: const Icon(Icons.filter_list, color: _textSecondary, size: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ],
        const SizedBox(height: 12),
        if (_friends.isEmpty)
          _buildEmptyFriends()
        else if (filteredFriends.isEmpty)
          Center(child: Text('No friends match that search', style: TextStyle(color: _textSecondary, fontSize: 13)))
        else
          ...filteredFriends.map((friend) => _buildFriendCard(friend)),
      ],
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final username = friend['username'] ?? friend['email'] ?? 'Unknown';
    final email = friend['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FriendProfileScreen(friendUid: friend['uid'], username: username)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _avatar(username, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(email, style: const TextStyle(color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              // View profile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: const Text('View', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              // Remove
              IconButton(
                icon: Icon(Icons.person_remove_outlined, color: _textSecondary.withOpacity(0.5), size: 18),
                onPressed: () => _confirmRemove(friend),
                tooltip: 'Remove friend',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemove(Map<String, dynamic> friend) {
    final username = friend['username'] ?? friend['email'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove friend', style: TextStyle(color: _textPrimary)),
        content: Text('Remove $username from your friends?', style: const TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _textSecondary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _removeFriend(friend['uid']); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name, {double size = 40, Color color = _accent}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(color: _bg, fontWeight: FontWeight.bold, fontSize: size * 0.38),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  Widget _buildEmptyFriends() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: _accent.withOpacity(0.15)),
              ),
              child: const Icon(Icons.people_outline, size: 40, color: _accent),
            ),
            const SizedBox(height: 16),
            const Text('No friends yet', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Search by username or email above to add friends', style: TextStyle(color: _textSecondary, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}