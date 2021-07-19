xquery version "3.1";

module namespace dicey="http://line-o.de/xq/dicey";

declare function dicey:sequence ($n as xs:integer,
        $generator as map(xs:string, item())) as item()* {
    fold-left(
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

declare function dicey:random-from ($sequence as item()*, 
        $generator as map(xs:string, item())) as map(*) {
    let $random-index := xs:integer($generator?number * (count($sequence))) + 1
    return map:merge((
        map {
            "_dicey": true(),
            "_index": $random-index,
            "_item": $sequence[$random-index],
            "_next": function () {
                dicey:random-from($sequence, $generator?next())
            }
        },
        $generator
    ))
};


declare function dicey:random-from-characters ($n as xs:integer, $characters as xs:string) as xs:string {
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

};

(: standard dice :)

declare function dicey:d6() as map(*) {
    dicey:d6(random-number-generator())
};

declare function dicey:d6($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 6, $generator)
};

declare function dicey:d4() as map(*) {
    dicey:d4(random-number-generator())
};

declare function dicey:d4($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 4, $generator)
};

declare function dicey:d12() as map(*) {
    dicey:d12(random-number-generator())
};

declare function dicey:d12($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 12, $generator)
};

declare function dicey:d20() as map(*) {
    dicey:d12(random-number-generator())
};

declare function dicey:d20($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 20, $generator)
};

declare function dicey:d100() as map(*) {
    dicey:d100(random-number-generator())
};

declare function dicey:d100($generator as map(*)) as map(*) {
    dicey:ranged-random-integer(1, 100, $generator)
};
