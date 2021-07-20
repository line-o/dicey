# dicey

> Just a bunch of random functions 

<img title="dicey library logo" alt="A blue icosahedron (twenty-sided dice) with one greek letter on each side" src="src/icon.svg" width="30%">

## Introduction

Import the module with

```xquery
import module namespace dicey="http://line-o.de/xq/dicey";
```

Now you can throw a (six-sided) dice.

```xquery
dicey:d6()?_item
```

The library augments the default `fn:random-number-generator` in several ways.
So, you can use dicey random number generators as if they were the XQuery built-ins.

The added functionality lies in additional keys in the returned map

- `_dicey`: if this is true() you have an augmented random at your hands
- `_item`: a _thing_ derived from the current random number 
- `_next`: a wrapped call to `next` that will produce the next augmented generator of the __current__ type

For `dicey:d6`, for example, `_item` will always be a xs:integer between 1 and 6.

```xquery
dicey:d6()?_next()?_next()?_item
```

The underscores might be an acquired taste, but the decision was made after reading the [specification of fn:random-number-generator](https://www.w3.org/TR/xpath-functions-31/#func-random-number-generator). Specifically this sentence struck a chord:

> The map returned by the fn:random-number-generator function may contain additional entries beyond those specified here, but it must match the type map(xs:string, item()). The meaning of any additional entries is ·implementation-defined·. To avoid conflict with any future version of this specification, the keys of any such entries should start with an underscore character.

## Alea iacta est

`dicey:sequence` is handy whenever you need more than one
random value. 

Throw one dice three times in a row:

```xquery
dicey:sequence(3, dicey:d6())?sequence
```
It also works with the built-in random number generator.

```xquery
dicey:sequence(9, random-number-generator())?sequence
```

**Note:**
For a (specific) number of reasons `dicey:sequence` returns a map with:

- _sequence:_ the sequence of n random items
- _generator:_ the random number generator in use

The `sequence` key value is what you are usually after.
Read on to learn what the other key is about.

## Seeded random

When you provide your specific random, throwing a dice 
will have a reproducible outcome.

```xquery
let $piked-dice := dicey:d6(random-number-generator(103))
return dicey:sequence(6, $piked-dice)?sequence
```

It is also interesting to continue using the same dice across different uses.

```xquery
let $piked-dice := dicey:d6(random-number-generator(103))
let $first-batch := dicey:sequence(6, $piked-dice)
return (
    $first-batch?sequence,
    dicey:sequence(6, $first-batch?_next())
)
```

Or get a hold of the plain `random-number-generator` again. That way you can set up a different dice and throw that, for example.

```xquery
let $piked-dice := dicey:d6(random-number-generator(103))
let $d20 := dicey:d20($piked-dice?next())
return (
    $piked-dice?_item,
    $d20?_item
)
```

## One in a million

What if you need a random number in an arbitrary range?

For integers:

```xquery
dicey:ranged-random-integer(1, 1000000)?_item
```

For decimals:

```xquery
dicey:ranged-random(-1.71, 2.46)?_item
```

Those two can of course be used with `dicey:sequence`.
They also both have a signature that accepts a random number generator as the third parameter.

## Picking items at random

If you want to pick n items from a sequence, so that each unique item will only
be returned once you can use the `permute` function returned by `random-number-generator`.

```xquery
random-number-generator()?permute($sequence)
=> subsequence(1, $n)
```

Or, you can use `dicey:pick` that achieves the same result, but lazily by (re)moving items
at random indeces.

```xquery
dicey:pick($n, $sequence, random-number-generator())?sequence
```

`dicey:pick` returns a map with following properties:

- _sequence:_ the sequence of n items that were picked
- _from:_ the remainder of items from the original sequence
- _generator:_ the random number generator in use

## Beyond Numbers

The library can help you pick all kinds of data at random. 
That is particularly useful for assembling test-data.

Construct a string with ten random small latin characters:

```xquery
dicey:random-from-characters(10, "abcdefghijklmnopqrstuvwxyz")?_item
```

Pick _something_ at random:

```xquery
let $stuff-to-choose-from :=
(
    map { 
        "name": "alice", 
        "id": 1
    }, 
    map { 
        "name": "bob",
        "id": 2
    }
)

dicey:sequence(1,
    dicey:random-from(
        $stuff-to-choose-from, random-number-generator())
    )?sequence

```

## Roll your own random 

The example above could be generalized into a function creating fake users.

```xquery
xquery version "3.1";
import module namespace dicey="http://line-o.de/xq/dicey";

declare variable $local:names := ("alice", "bob");
declare function local:random-user ($generator as map(xs:string, item())) as map(*) {
    let $fake-user := map {
        "id": dicey:ranged-random-integer(1, 10000, $generator)?_item,
        "name": dicey:random-from($local:names, $generator)?_item
    }

    return
        map:merge((
            map {
                "_dicey": true(),
                "_item":  $fake-user,
                "_next": function() {
                    local:random-user($generator?next())
                }
            },
            $generator
        )) 
};

dicey:sequence(2, 
    local:random-user(
        random-number-generator()))?sequence
```

## Compatibility

While the primary target is eXistdb (**starting from version 5.3.0**) the [library module](src/content/dicey.xqm) itself should be compatible with any XQuery 3.1 runtime (e.g. saxon 10, baseX 9.5.x).

## Contributing

I am keen to hear your feedback and welcome additional tests, examples and documentation.
If you find a bug or want to propose a new feature please open an issue or pull request.

## Development

To make developing as seamless as possible some `npm` and `gulp` scripts are included in the
project. 

### Prerequisites

- node 12+

Install dependencies with

```bash
npm i
```

### Installation (existdb)

```bash
gulp install
```

builds the XAR-package and uploads it to the server defined in [.existdb.json](.existdb.json).


### File Watcher

```bash
gulp watch
```

watches for changes in either the library module, the specs or the testrunner and 
will package the XAR and upload it to the database instance when changes are saved to disk.

### Tests

The [XQSuite with tests](src/test/dicey-spec.xqm) can be run from
within existdb using the [testrunner](src/test/run-tests.xq) or
from the commandline using `npm`.

```bash
npm test
```

## License

MIT
