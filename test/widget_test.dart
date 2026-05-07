import 'package:flutter_test/flutter_test.dart';

import 'package:offline_ai/core/constants/model_catalog.dart';

void main() {
  test('catalog has Gemma 4 and Qwen3.5', () {
    expect(ModelCatalog.byId('gemma-4-e2b-it-q4km'), isNotNull);
    expect(ModelCatalog.byId('qwen3.5-0.8b-q4km'), isNotNull);
  });
}
