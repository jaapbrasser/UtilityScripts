function CountRegex(inputstring, inputregex) {
    return Object.keys(inputstring.split(inputregex)).length-1;
}
console.log(CountRegex('222foo2foo222foo222','foo'));