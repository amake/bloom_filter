# bloom_filter

A stand-alone Bloom filter implementation written in Dart inspired by
[Java-BloomFilter][Java-BloomFilter].

[Java-BloomFilter]: https://github.com/magnuss/java-bloomfilter

## Bloom filters

Bloom filters are used for set membership tests. They are fast and
space-efficient at the cost of accuracy. Although there is a certain probability
of error, Bloom filters never produce false negatives.

## Usage example

To create an empty Bloom filter, just call the constructor with the required
false positive probability and the number of elements you expect to add to the
Bloom filter.

```dart
double falsePositiveProbability = 0.1;
int expectedNumberOfElements = 100;

BloomFilter bloomFilter = new
BloomFilter<String>.withProbability(falsePositiveProbability, expectedNumberOfElements);
```

The constructor chooses a length and number of hash functions which will provide
the given false positive probability (approximately). Note that if you insert
more elements than the number of expected elements you specify, the actual false
positive probability will rapidly increase.

After the Bloom filter has been created, new elements may be added using the
`add` method.

```dart
bloomFilter.add("foo");
```

To check whether an element has been stored in the Bloom filter, use the
`mightContain` method.

```dart
bloomFilter.mightContain("foo"); // returns true
```

Keep in mind that the accuracy of this method depends on the false positive
probability. It will always return true for elements which have been added to
the Bloom filter, but it may also return true for elements which have not been
added. The accuracy can be estimated using the
`expectedFalsePositiveProbability` getter.

## Saving & restoring a bloom filter

Lets create a bloom filter which is 10 bits in size that expects 3 elements to be added to it:

```dart
BloomFilter b = new BloomFilter.withSize(10, 3);
```

Lets add some values to it:

```dart
for (var i = 0; i < 3; i++) b.add(i.toRadixString(2));
```

We can then extract the bits which can then be stored:

```dart
final List<bool> bits = b.getBits();
// [true, false, true, true, true, false, true, false, true, false]
```

We can then recreate the bloom filter like so:

```dart
BloomFilter b2 = new BloomFilter.withSize(10, 3)
    ..setBits(bits);
```