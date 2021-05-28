xquery version "3.1";

module namespace dicey-spec="http://line-o.de/xq/dicey/spec";


import module namespace dicey="http://line-o.de/xq/dicey";

declare namespace test="http://exist-db.org/xquery/xqsuite";

declare variable $dicey-spec:fibo := (1,1,2,3,5,8,13);

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
 : see 
 :)
declare variable $dicey-spec:seeded-random :=
    random-number-generator(1234567890);

declare 
    %test:assertTrue
function dicey-spec:ranged-random () {
    let $min := -1
    let $max := 1
    let $n := dicey:ranged-random($min, $max, random-number-generator())?number

    return ($n >= $min and $n <= $max)
};

declare 
    %test:assertEquals(0.3230908805819064)
function dicey-spec:seeded-ranged-random () {
    dicey:ranged-random(-1, 1, 
        $dicey-spec:seeded-random)?number    
};

declare 
    %test:assertTrue
function dicey-spec:ranged-random-integer () {
    let $min := -1
    let $max := 1
    let $n := dicey:ranged-random-integer($min, $max, random-number-generator())?number

    return (
        $n instance of xs:integer and 
        $n >= $min and $n <= $max
    )
};

declare 
    %test:assertEquals(0)
function dicey-spec:seeded-ranged-random-integer () {
    dicey:ranged-random-integer(-1, 1, 
        $dicey-spec:seeded-random)?number    
};


declare 
    %test:assertTrue
function dicey-spec:random-from () {
    let $n := dicey:random-from($dicey-spec:fibo, random-number-generator())?number
    return $n = $dicey-spec:fibo
};

declare 
    %test:assertEquals(5)
function dicey-spec:seeded-random-from () {
    dicey:random-from($dicey-spec:fibo, 
        $dicey-spec:seeded-random)?number
};

declare 
    %test:assertTrue
function dicey-spec:d6 () {
    let $n := dicey:d6()?number
    return $n >= 1 and $n <= 6
};

declare 
    %test:assertEquals(4)
function dicey-spec:seeded-d6 () {
    dicey:d6($dicey-spec:seeded-random)?number
};

declare 
    %test:assertEquals(4, 2, 2, 3, 3)
function dicey-spec:five-seeded-d6 () {
    dicey:sequence(5, dicey:d6($dicey-spec:seeded-random))?sequence
};

declare
    %test:assertEquals(16, "c")
function dicey-spec:select-a-random-thing() {
    let $selection := dicey:random-from(
        $dicey-spec:things, $dicey-spec:seeded-random)?number

    return ($selection?id, $selection?name)
};
