import 'package:somnio/src/utils/banner.dart';
import 'package:test/test.dart';

void main() {
  group('lerpRgb', () {
    test('returns first color at t=0', () {
      final a = const Rgb(0, 0, 0);
      final b = const Rgb(255, 255, 255);
      final result = lerpRgb(a, b, 0.0);
      expect(result.r, 0);
      expect(result.g, 0);
      expect(result.b, 0);
    });

    test('returns second color at t=1', () {
      final a = const Rgb(0, 0, 0);
      final b = const Rgb(255, 255, 255);
      final result = lerpRgb(a, b, 1.0);
      expect(result.r, 255);
      expect(result.g, 255);
      expect(result.b, 255);
    });

    test('returns midpoint at t=0.5', () {
      final a = const Rgb(0, 100, 200);
      final b = const Rgb(100, 200, 0);
      final result = lerpRgb(a, b, 0.5);
      expect(result.r, 50);
      expect(result.g, 150);
      expect(result.b, 100);
    });

    test('clamps values to 0-255', () {
      final a = const Rgb(250, 250, 250);
      final b = const Rgb(260, 260, 260); // intentionally out of range
      final result = lerpRgb(a, b, 1.0);
      expect(result.r, 255);
      expect(result.g, 255);
      expect(result.b, 255);
    });
  });

  group('interpolateGradient', () {
    test('returns first stop at t=0', () {
      final result = interpolateGradient(0.0, gradientStops);
      expect(result.r, gradientStops.first.r);
      expect(result.g, gradientStops.first.g);
      expect(result.b, gradientStops.first.b);
    });

    test('returns last stop at t=1', () {
      final result = interpolateGradient(1.0, gradientStops);
      expect(result.r, gradientStops.last.r);
      expect(result.g, gradientStops.last.g);
      expect(result.b, gradientStops.last.b);
    });

    test('returns intermediate color at t=0.5', () {
      final result = interpolateGradient(0.5, gradientStops);
      // t=0.5 with 4 stops (3 segments) → scaled = 1.5
      // Between stops[1] (37,99,235) and stops[2] (124,58,237), localT=0.5
      expect(result.r, closeTo(80, 2));
      expect(result.g, closeTo(78, 2));
      expect(result.b, closeTo(236, 2));
    });

    test('clamps t below 0', () {
      final result = interpolateGradient(-1.0, gradientStops);
      expect(result.r, gradientStops.first.r);
      expect(result.g, gradientStops.first.g);
      expect(result.b, gradientStops.first.b);
    });

    test('clamps t above 1', () {
      final result = interpolateGradient(2.0, gradientStops);
      expect(result.r, gradientStops.last.r);
      expect(result.g, gradientStops.last.g);
      expect(result.b, gradientStops.last.b);
    });

    test('handles single stop', () {
      final single = [const Rgb(100, 100, 100)];
      final result = interpolateGradient(0.5, single);
      expect(result.r, 100);
      expect(result.g, 100);
      expect(result.b, 100);
    });
  });
}
