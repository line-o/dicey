xquery version "3.1";

module namespace dicey-spec="http://line-o.de/xq/dicey/spec";


import module namespace dicey="http://line-o.de/xq/dicey";

declare namespace test="http://exist-db.org/xquery/xqsuite";

declare variable $dicey-spec:fibo := (1, 1, 2, 3, 5, 8, 13);

declare variable $dicey-spec:things := (
    map{ "id": 1, "name": "a" },
    map{ "id": 10, "name": "c" },
    map{ "id": 11, "name": "a" },
    map{ "id": 2, "name": "h" },
    map{ "id": 20, "name": "a" },
    map{ "id": 16, "name": "c" },
    map{ "id": 8, "name": "a" },
    map{ "id": 31, "name": "i" },
    map{ "id": 9, "name": "aa" }
);

(:~
 : some seeds are not producing predictable results! 
 : see https://github.com/eXist-db/exist/issues/3915
 :)
declare variable $dicey-spec:seeded-random :=
    random-number-generator(1234567890);

declare 
    %test:assertTrue
function dicey-spec:ranged-random () {
    let $min := -10
    let $max := 0
    let $n := dicey:ranged-random($min, $max, random-number-generator())?_item

    return ($n >= $min and $n <= $max)
};

declare 
    %test:assertEquals(0.3230908805819064)
function dicey-spec:seeded-ranged-random () {
    dicey:ranged-random(-1, 1, 
        $dicey-spec:seeded-random)?_item
};

declare 
    %test:assertTrue
function dicey-spec:ranged-random-integer () {
    let $min := -1
    let $max := 1
    let $n := dicey:ranged-random-integer($min, $max, random-number-generator())?_item

    return (
        $n instance of xs:integer and 
        $n >= $min and $n <= $max
    )
};

declare 
    %test:assertEquals(0)
function dicey-spec:seeded-ranged-random-integer () {
    dicey:ranged-random-integer(-1, 1, 
        $dicey-spec:seeded-random)?_item    
};


declare 
    %test:assertTrue
function dicey-spec:random-from () {
    let $n := dicey:random-from($dicey-spec:fibo, random-number-generator())?_item
    return $n = $dicey-spec:fibo
};

declare 
    %test:assertEquals(5)
function dicey-spec:seeded-random-from () {
    dicey:random-from($dicey-spec:fibo, 
        $dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(5)
function dicey-spec:seeded-random-from-has-index () {
    dicey:random-from($dicey-spec:fibo, 
        $dicey-spec:seeded-random)?_index
};

declare 
    %test:assertTrue
function dicey-spec:seeded-random-from-selects-item-at-number () {
    let $random := dicey:random-from($dicey-spec:fibo, random-number-generator())
    return
        $dicey-spec:fibo[$random?_index] eq $random?_item
};

declare
    %test:assertEquals(0.6615454402909532, 0.2737395224464364, 0.20389978922664642)
function dicey-spec:seeded-sequence () {
    dicey:sequence(3, $dicey-spec:seeded-random)?sequence
};

declare
    %test:assertEmpty
function dicey-spec:seeded-sequence-zero () {
    dicey:sequence(0, $dicey-spec:seeded-random)?sequence
};

declare
    %test:assertError("dicey:argument-error")
function dicey-spec:seeded-sequence-negative () {
    dicey:sequence(-1, $dicey-spec:seeded-random)
};

declare
    %test:assertEquals(0.6615454402909532, 0.2737395224464364, 0.20389978922664642)
function dicey-spec:seeded-array () {
    dicey:array(3, $dicey-spec:seeded-random)?array?*
};

declare
    %test:assertEmpty
function dicey-spec:seeded-array-zero () {
    dicey:array(0, $dicey-spec:seeded-random)?array?*
};

declare
    %test:assertError("dicey:argument-error")
function dicey-spec:seeded-array-negative () {
    dicey:array(-1, $dicey-spec:seeded-random)
};

declare
    %test:assertEmpty
function dicey-spec:pick-zero-from-array-returns-empty-array () {
    dicey:pick(0, array{1 to 8}, $dicey-spec:seeded-random)?array?*
};

declare
    %test:assertEquals(6,2,3,5)
function dicey-spec:pick-from-array-returns-correct-array () {
    dicey:pick(4, array{1 to 8}, $dicey-spec:seeded-random)?array?*
};

declare
    %test:assertEquals(1,4,7,8)
function dicey-spec:pick-returns-correct-remainder-array () {
    dicey:pick(4, array{1 to 8}, $dicey-spec:seeded-random)?from?*
};

declare
    %test:assertEquals(6,2,3,5,4,1,8,7)
function dicey-spec:pick-all-from-array-returns-correct-array () {
    dicey:pick(8, array{1 to 8}, $dicey-spec:seeded-random)?array?*
};

declare
    %test:assertEmpty
function dicey-spec:pick-all-from-array-returns-correct-remainder () {
    dicey:pick(8, array{1 to 8}, $dicey-spec:seeded-random)?from?*
};

declare
    %test:assertError("dicey:argument-error")
function dicey-spec:pick-n-larger-than-array-size-error () {
    dicey:pick(9, array{1 to 8}, $dicey-spec:seeded-random)
};

declare
    %test:assertError("dicey:argument-error")
function dicey-spec:pick-negative-n-from-array-error () {
    dicey:pick(-1, array{1 to 8}, $dicey-spec:seeded-random)
};

declare
    %test:assertEmpty
function dicey-spec:pick-zero-returns-empty-sequence () {
    dicey:pick(0, (1 to 8), $dicey-spec:seeded-random)?sequence
};

declare
    %test:assertEquals(6,2,3,5)
function dicey-spec:pick-returns-correct-sequence () {
    dicey:pick(4, (1 to 8), $dicey-spec:seeded-random)?sequence
};

declare
    %test:assertEquals(1,4,7,8)
function dicey-spec:pick-returns-correct-remainder () {
    dicey:pick(4, (1 to 8), $dicey-spec:seeded-random)?from
};

declare
    %test:assertEquals(6,2,3,5,4,1,8,7)
function dicey-spec:pick-all-returns-correct-sequence () {
    dicey:pick(8, (1 to 8), $dicey-spec:seeded-random)?sequence
};

declare
    %test:assertEmpty
function dicey-spec:pick-all-returns-correct-remainder () {
    dicey:pick(8, (1 to 8), $dicey-spec:seeded-random)?from
};

declare
    %test:assertError("dicey:argument-error")
function dicey-spec:pick-n-larger-than-sequence-error () {
    dicey:pick(9, (1 to 8), $dicey-spec:seeded-random)
};

declare
    %test:assertError("dicey:argument-error")
function dicey-spec:pick-negative-n-error () {
    dicey:pick(-1, (1 to 8), $dicey-spec:seeded-random)
};

declare 
    %test:assertTrue
function dicey-spec:d6 () {
    let $n := dicey:d6()?_item
    return $n >= 1 and $n <= 6
};

declare 
    %test:assertEquals(3)
function dicey-spec:seeded-d4 () {
    dicey:d4($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(4)
function dicey-spec:seeded-d6 () {
    dicey:d6($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(6)
function dicey-spec:seeded-d8 () {
    dicey:d8($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(8)
function dicey-spec:seeded-d12 () {
    dicey:d12($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(14)
function dicey-spec:seeded-d20 () {
    dicey:d20($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(22)
function dicey-spec:seeded-d32 () {
    dicey:d32($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(40)
function dicey-spec:seeded-d60 () {
    dicey:d60($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertEquals(66)
function dicey-spec:seeded-d100 () {
    dicey:d100($dicey-spec:seeded-random)?_item
};

declare 
    %test:assertTrue
function dicey-spec:coinflip-label () {
    dicey:coinflip()?_item = ("head", "tail")
};

declare 
    %test:assertTrue
function dicey-spec:coinflip-index () {
    dicey:coinflip()?_index = (1, 2)
};

declare 
    %test:assertEquals(2)
function dicey-spec:seeded-coinflip-index () {
    dicey:coinflip($dicey-spec:seeded-random)?_index
};

declare
    %test:assertEquals(4, 2, 2, 3, 3)
function dicey-spec:five-seeded-d6 () {
    dicey:sequence(5, dicey:d6($dicey-spec:seeded-random))?sequence
};

declare
    %test:assertEquals(16, "c")
function dicey-spec:select-a-random-thing () {
    let $selection := dicey:random-from(
        $dicey-spec:things, $dicey-spec:seeded-random)?_item

    return ($selection?id, $selection?name)
};

declare
    %test:assertEquals("rhfljdxokb")
function dicey-spec:a-random-string () {
    dicey:random-from-characters(10, "abcdefghijklmnopqrstuvwxyz",
        $dicey-spec:seeded-random)?_item
};
