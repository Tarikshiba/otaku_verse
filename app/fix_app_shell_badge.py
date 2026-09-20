import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'r') as f:
    content = f.read()

# Fix 1: Add else to _verifierNotifAmis
old_verif = """  Future<void> _verifierNotifAmis() async {
    try {
      final demandes = await FriendsService().demandesRecues();
      if (mounted && demandes.isNotEmpty) {
        setState(() => _notifAmis = true);
      }
    } catch (_) {}
  }"""
new_verif = """  Future<void> _verifierNotifAmis() async {
    try {
      final demandes = await FriendsService().demandesRecues();
      if (mounted) {
        setState(() => _notifAmis = demandes.isNotEmpty);
      }
    } catch (_) {}
  }"""
content = content.replace(old_verif, new_verif)

# Fix 2: Await Navigator.push for Amis and refresh badge
old_amis_tap = """_buildSideNavButton('Amis', Icons.people_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AmisScreen())), isRight: true),"""
new_amis_tap = """_buildSideNavButton('Amis', Icons.people_rounded, () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AmisScreen()));
                      _verifierNotifAmis();
                    }, isRight: true),"""
content = content.replace(old_amis_tap, new_amis_tap)

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'w') as f:
    f.write(content)
