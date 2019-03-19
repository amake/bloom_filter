// Copyright (c) 2016, kseo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:bloom_filter/bloom_filter.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('BloomFilter', () {
    final uuid = new Uuid();

    test('add', () {
      BloomFilter b = new BloomFilter.withProbability(0.01, 100);

      for (var i = 0; i < 100; i++) {
        String val = uuid.v4().toString();
        b.add(val);
        expect(b.mightContain(val), isTrue);
      }
    });

    test('BloomFilter.withProbability', () {
      BloomFilter b = new BloomFilter.withProbability(0.01, 100);

      for (var i = 0; i < 10; i++) {
        b.add(i.toRadixString(2));
        expect(b.mightContain(i.toRadixString(2)), isTrue);
      }
      expect(b.mightContain(uuid.v4()), isFalse);
    });

    test('BloomFilter.withSize', () {
      BloomFilter b = new BloomFilter.withSize(10, 3);

      for (var i = 0; i < 10; i++) {
        b.add(i.toRadixString(2));
        expect(b.getBits().length, equals(10));
      }
    });

    test('getBits and setBits', () {
      BloomFilter b = new BloomFilter.withSize(10, 3);

      for (var i = 0; i < 10; i++) {
        b.add(i.toRadixString(2));
      }

      BloomFilter b2 = new BloomFilter.withSize(10, 3)..setBits(b.getBits());

      expect(b.getBits(), equals(b2.getBits()));

      // check the values 0 - 9 are present in b2
      for (var i = 0; i < 10; i++) {
        expect(b2.mightContain(i.toRadixString(2)), isTrue);
      }
    });

    test('toMap', () {
      BloomFilter b = new BloomFilter.withSize(10, 3);

      for (var i = 0; i < 10; i++) {
        b.add(i.toRadixString(2));
      }
      final bits = b.getBits();
      final map = b.toMap();

      expect(bits[0], map[0]);
    });
  });
}
