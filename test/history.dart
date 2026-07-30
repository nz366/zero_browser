class Node {
  final String url;
  final Node? parent;
  final List<Node> children = [];
  int activeChild = -1;

  Node(this.url, this.parent);

  bool get hasBranched => children.length > 1;
}

class BranchingHistory {
  final Node home = Node('browser://newtab', null);
  late Node _current = home;

  String get current => _current.url;
  bool get atHome => _current == home;
  bool get hasBranched => _current.hasBranched;

  // FIXED: Now relies on activeChild rather than just list emptiness
  bool get hasForward => _current.activeChild >= 0;

  // FIXED: Typo corrected from hasBackWard
  bool get hasBackward => _current.parent != null;

  void visit(String url) {
    // FIXED: Check if ANY child matches this URL to prevent duplicating branches
    final existingIndex = _current.children.indexWhere((c) => c.url == url);

    if (existingIndex >= 0) {
      _current.activeChild = existingIndex; // Switch to the existing branch
      _current = _current.children[existingIndex];
    } else {
      final node = Node(url, _current);
      _current.children.add(node);
      _current.activeChild = _current.children.length - 1;
      _current = node;
    }
  }

  int back(int steps) {
    var taken = 0;
    while (taken < steps && _current.parent != null) {
      _current = _current.parent!;
      taken++;
    }
    return taken;
  }

  int forward(int steps) {
    var taken = 0;
    while (taken < steps && _current.activeChild >= 0) {
      _current = _current.children[_current.activeChild];
      taken++;
    }
    return taken;
  }

  // FIXED: Single traversal to avoid O(2N) complexity
  int goHome() {
    int taken = 0;
    while (_current.parent != null) {
      _current = _current.parent!;
      taken++;
    }
    return taken;
  }
}

// --- TEST SUITE ---
void main() {
  final history = BranchingHistory();

  print('1. Initial State:');
  print('Current: ${history.current}');
  print('Has Backward: ${history.hasBackward}');
  print('Has Forward: ${history.hasForward}\n');

  print('2. Visiting page1, page2, page3:');
  history.visit('page1');
  history.visit('page2');
  history.visit('page3');
  print('Current: ${history.current}');
  print('Has Backward: ${history.hasBackward}');
  print('Has Forward: ${history.hasForward}\n');

  print('3. Going backwards 2 steps:');
  int stepsTaken = history.back(2);
  print('Steps actually taken: $stepsTaken (Expected: 2)');
  print('Current: ${history.current} (Expected: page1)');
  print('Has Backward: ${history.hasBackward} (Expected: true)');
  print('Has Forward: ${history.hasForward} (Expected: true)\n');

  print('4. Branching to page X:');
  history.visit('page X'); // Creates a new branch from page1
  print('Current: ${history.current}');
  print(
    'Has Branched (at page1)? ${history._current.parent?.hasBranched} (Expected: true)',
  );
  print('Has Forward: ${history.hasForward} (Expected: false)\n');

  print('5. Going back to page1 and revisiting page2 (switching branches):');
  history.back(1);
  history.visit(
    'page2',
  ); // Should seamlessly switch back to the page2 -> page3 branch
  print('Current: ${history.current}');
  print(
    'Has Forward: ${history.hasForward} (Expected: true, because page3 is still ahead)',
  );

  history.forward(1);
  print(
    'Moving forward 1 step... Current: ${history.current} (Expected: page3)\n',
  );

  print('6. Going home from page3:');
  int homeSteps = history.goHome();
  print('Steps taken to get home: $homeSteps (Expected: 3)');
  print('Current: ${history.current} (Expected: browser://newtab)');
  print('Has Backward: ${history.hasBackward} (Expected: false)');
  print('Has Forward: ${history.hasForward} (Expected: true)');
}
