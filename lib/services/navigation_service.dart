import 'package:flutter/foundation.dart';

class NavigationService extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void goTo(int i) {
    if (_index != i) {
      _index = i;
      notifyListeners();
    }
  }
}
