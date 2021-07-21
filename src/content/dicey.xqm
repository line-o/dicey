xquery version "3.1";

module namespace dicey="http://line-o.de/xq/dicey";

declare function dicey:sequence ($n as xs:integer,
        $generator as map(xs:string, item())) as map(*) {
    if ($n < 0)
    then error(xs:QName("dicey:argument-error"), "$n must be zero or greater, but got " || $n || ".")
    else fold-left(
            1 to $n,
            map { "sequence": (), "generator": $generator},
            if ($generator?_dicey) then dicey:reducer#2 else dicey:built-in-reducer#2
        )
};

declare %private
function dicey:reducer ($accu as map(*), $counter as xs:integer) as map(*) {
    map {
        "sequence": ($accu?sequence, $accu?generator?_item),
        "generator": $accu?generator?_next()
    }
};

declare %private 
function dicey:built-in-reducer ($accu as map(*), $counter as xs:integer) as map(*) {
    map {
        "sequence": ($accu?sequence, $accu?generator?number),
        "generator": $accu?generator?next()
    }
};

declare function dicey:array ($n as xs:integer,
        $generator as map(xs:string, item())) as map(*) {
    if ($n < 0)
    then error(xs:QName("dicey:argument-error"), "$n must be zero or greater, but got " || $n || ".")
    else fold-left(
            1 to $n,
            map { "array": [], "generator": $generator},
            if ($generator?_dicey) then dicey:array-reducer#2 else dicey:built-in-array-reducer#2
        )
};

declare %private
function dicey:array-reducer ($accu as map(*), $counter as xs:integer) as map(*) {
    map {
        "array": array:append($accu?array, $accu?generator?_item),
        "generator": $accu?generator?_next()
    }
};

declare %private 
function dicey:built-in-array-reducer ($accu as map(*), $counter as xs:integer) as map(*) {
    map {
        "array": array:append($accu?array, $accu?generator?number),
        "generator": $accu?generator?next()
    }
};

declare function dicey:pick ($n as xs:integer, $from as item()*,
        $generator as map(xs:string, item())) as map(*) {
    typeswitch ($from)
    case array(*) return dicey:pick-from-array($n, $from, $generator)
    default return dicey:pick-from-sequence($n, $from, $generator)
};

declare function dicey:pick-from-array ($n as xs:integer, $from as array(*),
        $generator as map(xs:string, item())) as map(*) {
    if ($n < 0)
    then error(xs:QName("dicey:argument-error"), "Only zero or more items can be picked, but $n was " || $n || ".")
    else if ($n > array:size($from))
    then error(xs:QName("dicey:argument-error"), "Sequence must have at least as much entries as need to be picked. Given sequence has " || count($from) || " entries, but " || $n || " items were requested.")
    else
        fold-left(
            1 to $n,
            map { "array": [], "generator": $generator, "from": $from },
            dicey:array-picker#2
        )
};

declare %private
function dicey:array-picker ($accu as map(*), $counter as xs:integer) as map(*) {
    let $array := $accu?from
    let $next := dicey:random-from-array($array, $accu?generator)

    return
        map {
            "array": array:append($accu?array, $next?_item),
            "generator": $next?next(),
            "from": array:remove($array, $next?_index)
            (: "from": array:join((
                array:subarray($array, 1, $next?_index - 1),
                array:subarray($array, $next?_index + 1)
            )) :)
        }
};

declare function dicey:pick-from-sequence ($n as xs:integer, $from as item()*,
        $generator as map(xs:string, item())) as map(*) {
    if ($n < 0)
    then error(xs:QName("dicey:argument-error"), "Only zero or more items can be picked, but $n was " || $n || ".")
    else if ($n > count($from))
    then error(xs:QName("dicey:argument-error"), "Sequence must have at least as much entries as need to be picked. Given sequence has " || count($from) || " entries, but " || $n || " items were requested.")
    else
        fold-left(
            1 to $n,
            map { "sequence": (), "generator": $generator, "from": $from },
            dicey:sequence-picker#2
        )
};

declare %private
function dicey:sequence-picker ($accu as map(*), $counter as xs:integer) as map(*) {
    let $seq := $accu?from
    let $next := dicey:random-from($seq, $accu?generator)

    return
        map {
            "sequence": ($accu?sequence, $next?_item),
            "generator": $next?next(),
            "from": (
                subsequence($seq, 1, $next?_index - 1),
                subsequence($seq, $next?_index + 1)
            )
        }
};

declare function dicey:ranged-random ($min as xs:decimal, $max as xs:decimal) as map(*) {
    dicey:ranged-random($min, $max, random-number-generator())
};

declare function dicey:ranged-random ($min as xs:decimal, $max as xs:decimal, 
        $generator as map(xs:string, item())) as map(*) {
    map:merge((
        map {
            "_dicey": true(),
            "_item": ($generator?number * ($max - $min)) + $min,
            "_next": function () {
                dicey:ranged-random($min, $max, $generator?next())
            }
        },
        $generator
    )) 
};

declare function dicey:ranged-random-integer ($min as xs:integer, $max as xs:integer) as map(*) {
    dicey:ranged-random-integer($min, $max, random-number-generator())
};

declare function dicey:ranged-random-integer ($min as xs:integer, $max as xs:integer,
        $generator as map(xs:string, item())) as map(*) {
    map:merge((
        map {
            "_dicey": true(),
            "_item": xs:integer(round($generator?number * ($max - $min)) + $min),
            "_next": function () {
                dicey:ranged-random-integer($min, $max,
                    $generator?next())
            }
        },
        $generator
    ))
};

declare function dicey:random-from ($sequence-or-array as item()*) as map(*) {
    dicey:random-from($sequence, random-number-generator())
};

declare function dicey:random-from ($sequence-or-array as item()*, 
        $generator as map(xs:string, item())) as map(*) {
    typeswitch ($sequence-or-array)
    case array(*) return dicey:random-from-array($sequence-or-array, $generator)
    default return dicey:random-from-sequence($sequence-or-array, $generator)
};

declare function dicey:random-from-sequence ($sequence as item()*, 
        $generator as map(xs:string, item())) as map(*) {
    let $random-index := xs:integer($generator?number * (count($sequence))) + 1
    return map:merge((
        map {
            "_dicey": true(),
            "_index": $random-index,
            "_item": $sequence[$random-index],
            "_next": function () {
                dicey:random-from-sequence($sequence, $generator?next())
            }
        },
        $generator
    ))
};

declare function dicey:random-from-array ($array as array(*), 
        $generator as map(xs:string, item())) as map(*) {
    let $random-index := xs:integer($generator?number * array:size($array)) + 1
    return map:merge((
        map {
            "_dicey": true(),
            "_index": $random-index,
            "_item": $array($random-index),
            "_next": function () {
                dicey:random-from-array($array, $generator?next())
            }
        },
        $generator
    ))
};

declare function dicey:random-from-characters ($n as xs:integer, $characters as xs:string) as map(*) {
    dicey:random-from-characters($n, $characters, random-number-generator())
};

declare function dicey:random-from-characters ($n as xs:integer, $characters as xs:string, $generator as map(*)) as map(*) {
    let $rnd := 
        dicey:sequence($n, 
            dicey:random-from(string-to-codepoints($characters), $generator))

    let $string := 
        $rnd?sequence
        => for-each(codepoints-to-string(?))
        => string-join()

    return map:merge((
        $rnd?generator,
        map {
            "_item": $string,
            "_next": $rnd?generator?_next
        }
    ))
};

(: coinflip :)

declare function dicey:coinflip() as map(*) {
    dicey:coinflip(random-number-generator())
};

declare function dicey:coinflip($generator as map(*)) as map(*) {
    dicey:random-from(("head", "tail"), $generator)
};

(: standard dice, platonic solids :)

(: tetrahedron :)

declare function dicey:d4() as map(*) {
    dicey:d4(random-number-generator())
};

declare function dicey:d4($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 4, $generator)
};

(: cube :)

declare function dicey:d6() as map(*) {
    dicey:d6(random-number-generator())
};

declare function dicey:d6($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 6, $generator)
};

(: octahedron :)

declare function dicey:d8() as map(*) {
    dicey:d4(random-number-generator())
};

declare function dicey:d8($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 8, $generator)
};

(: icosahedron :)

declare function dicey:d12() as map(*) {
    dicey:d12(random-number-generator())
};

declare function dicey:d12($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 12, $generator)
};

(: dodecahedron :)

declare function dicey:d20() as map(*) {
    dicey:d12(random-number-generator())
};

declare function dicey:d20($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 20, $generator)
};

(: other dice :)

(: truncated icosahedron, buckyball, fullerene :)

declare function dicey:d32() as map(*) {
    dicey:d12(random-number-generator())
};

declare function dicey:d32($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 32, $generator)
};

(: dodecahedron with subdivided surfaces :)

declare function dicey:d60() as map(*) {
    dicey:d60(random-number-generator())
};

declare function dicey:d60($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 60, $generator)
};

(: spindle :)

declare function dicey:d100() as map(*) {
    dicey:d100(random-number-generator())
};

declare function dicey:d100($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 100, $generator)
};
