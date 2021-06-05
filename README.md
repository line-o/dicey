# dicey

> Just a bunch of random functions 

<img title="dicey library logo" alt="A fuming red cube with the symbols A and B on the two visible sides" src="src/icon.png" width="30%">

## Introduction

Throw a dice (with 6 sides).

```xquery
dicey:d6()?number
```

The library augments the default `fn:random-number-generator` in several ways.
So, you can use random number generators just as you would the XQuery standard one. But `d6` will always return xs:integers between 1 and 6.

```xquery
dicey:d6()?next()?next()?number
```

## Alea iacta est

`dicey:sequence` is handy whenever you need more than one
random value. It works with any dicey random generator - and
the standard one as well.

Throw one dice three times in a row:

```xquery
dicey:sequence(3, dicey:d6())?sequence
```

**Note:**
For a (random) number of reasons `dicey:sequence` returns a map.
The `sequence` key value is what you are usually after.
Read on to learn what the other key is about.

## Seeded random

When you provide your speficic random, throwing a dice 
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
    dicey:sequence(6, $first-batch?next())
)
```

Or get a hold of the plain `random-number-generator` again. That way you can set up a different dice and throw that, for example.

```xquery
let $piked-dice := dicey:d6(random-number-generator(103))
let $d20 := dicey:d20($piked-dice?generator?random())
return (
    $first-batch?sequence,
    $d20?next()?number
)
```

## One in a million

`dicey:n-integers-from-to` is convenient, if you just need a bunch of random integer values in a specific range.

```xquery
dicey:n-integers-from-to(1, 1, 1000000)
```

**Note:**
You will not be able to get a hold on the random number generator.

## Beyond Numbers

The library can help you pick all kinds of data at random. 
That is particularly useful for assembling test-data.

Construct a string with ten random small latin characters:

```xquery
dicey:random-from-characters(10, "abcdefghijklmnopqrstuvwxyz")?string
```

Pick _something_ at random:

```xquery
let $stuff-to-choose-from :=
(
    map { 
        "name": "alice", 
        "id": dicey:n-integers-from-to(1, 1, 1000000)
    }, 
    map { 
        "name": "bob",
        "id": dicey:n-integers-from-to(1, 1, 1000000)
    }
)

dicey:sequence(1,
    dicey:random-from(
        $stuff-to-choose-from, random-number-generator())
    )?sequence

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
