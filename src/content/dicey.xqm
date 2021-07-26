xquery version "3.1";

module namespace dicey = "http://line-o.de/xq/dicey";

(: Saxon does not declare map and array namespaces by default :)
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace array = "http://www.w3.org/2005/xpath-functions/array";

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

declare function dicey:draw ($n as xs:integer, $from as item()*) as map(*) {
    dicey:draw($n, $from, random-number-generator())
};

declare function dicey:draw ($n as xs:integer, $from as item()*,
        $generator as map(xs:string, item())) as map(*) {
    typeswitch ($from)
    case array(*) return dicey:draw-from-array($n, $from, $generator)
    default return dicey:draw-from-sequence($n, $from, $generator)
};

declare function dicey:draw-from-array ($n as xs:integer, $from as array(*),
        $generator as map(xs:string, item())) as map(*) {
    if ($n < 0)
    then error(xs:QName("dicey:argument-error"), "Only zero or more items can be drawn, but $n was " || $n || ".")
    else if ($n > array:size($from))
    then error(xs:QName("dicey:argument-error"), "Array must have at least as much entries as need to be drawn. Given array has " || array:size($from) || " entries, but " || $n || " items were requested.")
    else
        fold-left(
            1 to $n,
            map { "array": [], "generator": $generator, "from": $from },
            dicey:array-drawer#2
        )
};

declare %private
function dicey:array-drawer ($accu as map(*), $counter as xs:integer) as map(*) {
    let $array := $accu?from
    let $next := dicey:pick-from-array($array, $accu?generator)

    return
        map {
            "array": array:append($accu?array, $next?_item),
            "generator": $next?next(),
            "from": array:remove($array, $next?_index)
        }
};

declare function dicey:draw-from-sequence ($n as xs:integer, $from as item()*,
        $generator as map(xs:string, item())) as map(*) {
    if ($n < 0)
    then error(xs:QName("dicey:argument-error"), "Only zero or more items can be drawn, but $n was " || $n || ".")
    else if ($n > count($from))
    then error(xs:QName("dicey:argument-error"), "Sequence must have at least as much entries as need to be drawn. Given sequence has " || count($from) || " entries, but " || $n || " items were requested.")
    else
        fold-left(
            1 to $n,
            map { "sequence": (), "generator": $generator, "from": $from },
            dicey:sequence-drawer#2
        )
};

declare %private
function dicey:sequence-drawer ($accu as map(*), $counter as xs:integer) as map(*) {
    let $seq := $accu?from
    let $next := dicey:pick($seq, $accu?generator)

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

declare function dicey:pick ($from as item()*) as map(*) {
    dicey:pick($from, random-number-generator())
};

declare function dicey:pick ($from as item()*,
        $generator as map(xs:string, item())) as map(*) {
    typeswitch ($from)
    case array(*) return dicey:pick-from-array($from, $generator)
    default return dicey:pick-from-sequence($from, $generator)
};

declare function dicey:pick-from-sequence ($sequence as item()*, 
        $generator as map(xs:string, item())) as map(*) {
    let $random-index := xs:integer($generator?number * (count($sequence))) + 1
    return map:merge((
        map {
            "_dicey": true(),
            "_index": $random-index,
            "_item": $sequence[$random-index],
            "_next": function () {
                dicey:pick-from-sequence($sequence, $generator?next())
            }
        },
        $generator
    ))
};

declare function dicey:pick-from-array ($array as array(*), 
        $generator as map(xs:string, item())) as map(*) {
    let $random-index := xs:integer($generator?number * array:size($array)) + 1
    return map:merge((
        map {
            "_dicey": true(),
            "_index": $random-index,
            "_item": $array($random-index),
            "_next": function () {
                dicey:pick-from-array($array, $generator?next())
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
            dicey:pick(string-to-codepoints($characters), $generator))

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
    dicey:pick(("head", "tail"), $generator)
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
