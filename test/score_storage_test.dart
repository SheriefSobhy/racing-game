import 'package:flutter_test/flutter_test.dart';
import 'package:racing_game/services/score_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('best score is 0 at first, then saved and loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = ScoreStorage();

    expect(await storage.loadBestScore(), 0);

    await storage.saveBestScore(1234);
    expect(await storage.loadBestScore(), 1234);
  });
}
