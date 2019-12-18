// Copyright (c) 2016, kseo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:bloom_filter/bloom_filter.dart';
import 'package:collection/collection.dart';
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
      BloomFilter b = new BloomFilter.withSize(10, 5);
      expect(b.getBits().length, equals(10));
    });

    test('getBits and setBits', () {
      BloomFilter b = new BloomFilter.withSize(20, 10);

      for (var i = 0; i < 10; i++) {
        b.add(i.toRadixString(2));
      }

      BloomFilter b2 = new BloomFilter.withSize(20, 10)..setBits(b.getBits());

      expect(b.getBits(), equals(b2.getBits()));

      // check the values 0 - 9 are present in b2
      for (var i = 0; i < 10; i++) {
        expect(b2.mightContain(i.toRadixString(2)), isTrue);
      }
    });

    test('toMap', () {
      BloomFilter b = new BloomFilter.withSize(20, 10);

      for (var i = 0; i < 10; i++) b.add(i.toRadixString(2));

      final bits = b.getBits();
      final map = b.toMap();

      expect(bits[0], map[0]);
    });

    test('Jimmys test', () {
      BloomFilter bf = BloomFilter.withSize(8000, 2389);

      final userRef = 'HjWeN1NjllnZlJ1mIbCc';
      bf.add(userRef);
      print(bf);

      int lastIndex = -1;
      List<int> bitIndex = [];
      final bits = bf.getBits();
      while (true) {
        lastIndex = bits.indexOf(true, lastIndex + 1);
        if (lastIndex == -1) break;
        bitIndex.add(lastIndex);
      }
      print(bitIndex);
    });

    test('Store as 64', () {
      BloomFilter b = new BloomFilter.withSize(1000, 300);

      for (var i = 0; i < 300; i++) b.add(i.toRadixString(2));

      final bitVector = b.bitVectorListForStorage();
      print(bitVector);
      BloomFilter b2 = new BloomFilter.withSizeAndBitVector(
          20, 10, Uint32List.fromList(bitVector).buffer);

      // expect(b == b2, true);
    });

    test('hashes', () {
      String data = 'jimmy';
      int size = 814237;
      int expectedItems = 50000;

      BloomFilter b = new BloomFilter.withSize(size, expectedItems);
      var bh = b.hashIndexes(data);

      var bh2 =
          BloomFilter.hashIndexesWithSize<String>(size, expectedItems, data);
      print(bh);
      print(bh2);

      Function eq = const ListEquality().equals;
      expect(eq(bh, bh2), true);
    });

    test('Copy', () {
      final items = 43063;
      final b1 = BloomFilter.withProbability(0.01, items);
      for (int i = 0; i < items; i++) {
        b1.add(i);
      }
      for (int i = 0; i < items; i++) {
        expect(b1.mightContain(i), true);
      }
      print(b1.bitVectorSize);
      final b2 = BloomFilter.withSizeAndBitVector(b1.bitVectorSize, items,
          Uint32List.fromList(b1.bitVectorListForStorage()).buffer);
      expect(b1.bitVectorSize == b2.bitVectorSize, true);
      for (int i = 0; i < items; i++) {
        b2.mightContain(i);
      }
    });
  });
}
