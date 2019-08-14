// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' show exp, log, pow;

import 'bit_vector_web.dart';
import 'package:crypto/crypto.dart';

/// A implementation of Bloom filter, as described by
/// https://en.wikipedia.org/wiki/Bloom_filter
class BloomFilter<E> {
  /// Constructs an empty Bloom filter with a given false positive probability.
  /// The number of bits per element and the number of hash functions is
  /// estimated to match the false positive probability.
  factory BloomFilter.withProbability(
      double falsePositiveProbability, int expectedNumberOfElements) {
    final c = (-(log(falsePositiveProbability) / log(2))).ceil() /
        log(2); // c = k / ln(2)
    final k = ((-(log(falsePositiveProbability) / log(2))).ceil())
        .toInt(); // k = ceil(-log_2(false prob.))
    return new BloomFilter(c, expectedNumberOfElements, k);
  }

  static List<int> hashIndexesWithSize<E>(
      int bitSetSize, int expectedNumberOfElements, E data) {
    final double c = bitSetSize / expectedNumberOfElements;
    final int n = expectedNumberOfElements;
    final int k = ((bitSetSize / expectedNumberOfElements) * log(2)).round();

    final hashes = _createHashes(utf8.encode(data.toString()), k);
    final List<int> indexes = [];

    for (int hash in hashes) {
      final indexPosition = (hash % bitSetSize).abs();
      if (!indexes.contains(indexPosition)) indexes.add(indexPosition);
    }
    indexes.sort();
    return indexes;
  }

  factory BloomFilter.withSize(int bitSetSize, int expectedNumberOfElements) {
    final double c = bitSetSize / expectedNumberOfElements;
    final int n = expectedNumberOfElements;
    final int k = ((bitSetSize / expectedNumberOfElements) * log(2)).round();
    return new BloomFilter(c, n, k);
  }
  factory BloomFilter.withSizeAndBitVector(
      int bitSetSize, int expectedNumberOfElements, List<String> bitVector) {
    final double c = bitSetSize / expectedNumberOfElements;
    final int n = expectedNumberOfElements;
    final int k = ((bitSetSize / expectedNumberOfElements) * log(2)).round();
    return new BloomFilter(c, n, k, bitVector: bitVector);
  }

  BloomFilter(double bitsPerElement, int expectedElements, int hashFunctions,
      {List<String> bitVector})
      : _expectedNumOfElements = expectedElements,
        _k = hashFunctions,
        _bitVectorSize = (bitsPerElement * expectedElements).ceil(),
        _numOfAddedElements = 0,
        _bitVector = bitVector == null
            ? new BitVector((bitsPerElement * expectedElements).ceil())
            : BitVector.fromWordsString(bitVector);

  final BitVector _bitVector;
  final int _bitVectorSize;
  final int _expectedNumOfElements;
  int _numOfAddedElements;
  final int _k; // number of hash functions

  /// The number of elements added to the Bloom filter after is was constructed
  /// or after clear() was called.
  int get length => _numOfAddedElements;

  @override
  String toString() => _bitVector.toString();

  @override
  List<String> bitVectorListForStorage() => _bitVector.toListforStorage();

  List<bool> getBits() {
    final out = <bool>[];
    for (var i = 0; i < _bitVectorSize; i++)
      out.add(_bitVector[i] ? true : false);
    return out;
  }

  void setBits(List<bool> data) {
    for (var i = 0; i < data.length; i++) {
      if (data[i]) _bitVector.set(i);
    }
  }

  Map<int, bool> toMap() =>
      Map.fromIterable(List<int>.generate(_bitVectorSize, (int i) => i),
          key: (var i) => i, value: (var i) => _bitVector[i]);

  /// The probability of a false positive given the expected number of inserted
  /// elements.
  double get expectedFalsePositiveProbability {
    // (1 - e^(-k * n / m)) ^ k
    return pow(1 - exp((-_k * _expectedNumOfElements / _bitVectorSize)), _k);
  }

  /// Adds an element to the Bloom filter. The output from the element's
  /// toString() method is used as input to the hash functions.
  void add(E element) {
    List<int> hashes = _createHashes(utf8.encode(element.toString()), _k);
    for (int hash in hashes) {
      _bitVector.set((hash % _bitVectorSize).abs());
    }
    _numOfAddedElements++;
  }

  List<int> hashIndexes(E element) {
    final List<int> indexes = [];
    var hashes = _createHashes(utf8.encode(element.toString()), _k);
    for (int hash in hashes) {
      final indexPosition = (hash % _bitVectorSize).abs();
      if (!indexes.contains(indexPosition)) indexes.add(indexPosition);
    }
    indexes.sort();
    return indexes;
  }

  /// Adds all elements to the Bloom filter.
  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      add(element);
    }
  }

  /// Returns true if the element could have been inserted into the Bloom
  /// filter, false if this is definitely not the case.
  bool mightContain(E element) {
    List<int> hashes = _createHashes(utf8.encode(element.toString()), _k);
    for (int hash in hashes) {
      if (!_bitVector.has((hash % _bitVectorSize).abs())) {
        return false;
      }
    }
    return true;
  }

  /// Returns true if all the elements could have been inserted into the Bloom
  /// filter.
  bool containsAll(Iterable<E> elements) {
    for (E element in elements) {
      if (!mightContain(element)) return false;
    }
    return true;
  }

  /// Set all bits to false in the Bloom filter.
  void clear() {
    _bitVector.clearAll();
    _numOfAddedElements = 0;
  }
}

List<int> _digest(int salt, List<int> data) {
  List<int> result;
  Sink<Digest> sink =
      new ChunkedConversionSink.withCallback((List<Digest> digest) {
    result = digest.single.bytes;
  });

  md5.startChunkedConversion(sink)
    ..add([salt])
    ..add(data)
    ..close();

  return result;
}

List<int> _createHashes(List<int> data, int hashes) {
  List<int> result = new List<int>(hashes);

  int k = 0;
  int salt = 0;
  while (k < hashes) {
    List<int> digest = _digest(salt, data);
    salt++;

    for (var i = 0; i < digest.length / 4 && k < hashes; i++) {
      int h = 0;
      for (int j = (i * 4); j < (i * 4) + 4; j++) {
        h <<= 8;
        h |= digest[j] & 0xFF;
      }
      result[k] = h;
      k++;
    }
  }
  return result;
}
