import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'r') as f:
    content = f.read()

# Update _nextPage
old_next = """  void _nextPage() async {
    if (_currentPage == 0) {
      if (_animeChoisi != null) {
        _chargerArcs();
      } else {
        _arcChoisi = null; // Tous les animes -> pas d'arc possible
      }
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else if (_currentPage == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }"""

new_next = """  void _nextPage() async {
    if (_currentPage == 0) {
      if (_animeChoisi != null) {
        _chargerArcs();
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        setState(() => _currentPage++);
      } else {
        _arcChoisi = null; // Tous les animes -> pas d'arc possible
        // On saute la page des arcs
        _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        setState(() => _currentPage = 2);
      }
    } else if (_currentPage == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }"""
if "On saute la page des arcs" not in content:
    content = content.replace(old_next, new_next)

# Ensure _prevPage exists to handle jumping back
if "void _prevPage()" not in content:
    old_build_footer = """  Widget _buildFooter() {"""
    new_build_footer = """  void _prevPage() {
    if (_currentPage == 2 && _animeChoisi == null) {
      // Retour direct à l'anime
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage = 0);
    } else if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  Widget _buildFooter() {"""
    content = content.replace(old_build_footer, new_build_footer)
else:
    # If _prevPage exists, patch it
    old_prev = """  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }"""
    new_prev = """  void _prevPage() {
    if (_currentPage == 2 && _animeChoisi == null) {
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage = 0);
    } else if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }"""
    content = content.replace(old_prev, new_prev)

# Fix max page display on page 3 (index 2) when skipping
# The text shows 1/3, 2/3, 3/3. But if skipped, 3/3 looks weird without 2/3.
# Wait, actually if anime is null, it should be a 2-step process conceptually.
old_step_text = """Text('${_currentPage + 1}/3', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),"""
new_step_text = """Text(
                  _animeChoisi == null 
                      ? '${_currentPage == 0 ? 1 : 2}/2' 
                      : '${_currentPage + 1}/3',
                  style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted),
                ),"""
content = content.replace(old_step_text, new_step_text)

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'w') as f:
    f.write(content)
