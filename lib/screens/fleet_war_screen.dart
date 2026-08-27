import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/ship.dart';
import '../services/fleet_war_service.dart';
import '../services/season.dart';

class FleetWarScreen extends StatefulWidget {
  const FleetWarScreen({super.key});

  @override
  State<FleetWarScreen> createState() => _FleetWarScreenState();
}

class _FleetWarScreenState extends State<FleetWarScreen> {
  final _fleetWarService = FleetWarService();
  final _shipNameController = TextEditingController();
  String? _myShipId;
  bool _loadingShip = true;
  bool _joining = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCurrentShip();
  }

  @override
  void dispose() {
    _shipNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentShip() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loadingShip = false);
      return;
    }
    final shipId = await _fleetWarService.currentShip(uid);
    if (!mounted) return;
    setState(() {
      _myShipId = shipId;
      _loadingShip = false;
    });
  }

  Future<void> _joinShip(String name) async {
    final uid = _uid;
    if (uid == null || name.trim().isEmpty) return;
    setState(() => _joining = true);
    await _fleetWarService.joinShip(uid: uid, shipName: name);
    if (!mounted) return;
    setState(() {
      _myShipId = shipIdFromName(name);
      _joining = false;
      _shipNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loggedIn = _uid != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Flottenkrieg')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Season ${currentSeasonKey()} · Punkte zählen für dein Schiff, Reset jeden Monatsanfang',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            if (!loggedIn)
              Text(
                'Keine Verbindung zum Konto - Flottenkrieg ist gerade nicht verfügbar.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              )
            else if (_loadingShip)
              const Center(child: CircularProgressIndicator())
            else if (_myShipId == null)
              _buildJoinForm(colorScheme)
            else
              Text(
                'Dein Schiff: $_myShipId',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 24),
            Text('Flottenrangliste:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Expanded(child: _buildLeaderboard(colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinForm(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Noch keinem Schiff beigetreten. Name eingeben, um mitzumachen:',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _shipNameController,
          decoration: const InputDecoration(labelText: 'Schiffsname', hintText: 'z. B. MS Freedom'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _joining ? null : () => _joinShip(_shipNameController.text),
          child: Text(_joining ? 'Beitreten ...' : 'Schiff beitreten'),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(ColorScheme colorScheme) {
    return StreamBuilder<List<Ship>>(
      stream: _fleetWarService.watchLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Rangliste gerade nicht verfügbar.', style: TextStyle(color: Colors.red)),
          );
        }
        final ships = snapshot.data ?? [];
        if (ships.isEmpty) {
          return Center(
            child: Text(
              'Noch keine Punkte diese Season - sei das erste Schiff!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          );
        }
        return ListView.separated(
          itemCount: ships.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final ship = ships[index];
            final isMine = ship.id == _myShipId;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMine ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(ship.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text('${ship.seasonScore} Pkt.', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
