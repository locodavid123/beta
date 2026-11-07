import 'package:beta/core/models/style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ArtStyle trims accidental whitespace from image paths', () {
    final style = ArtStyle.fromMap({
      'id': 'corte_cachorro',
      'name': 'Corte Cachorro',
      'category': 'Clásico',
      'imagePath': 'assets/images/corte_cachorro.png ',
      'description': 'Corte corto uniforme',
    });

    expect(style.imagePath, 'assets/images/corte_cachorro.png');
    expect(style.toMap()['imagePath'], 'assets/images/corte_cachorro.png');
  });
}
