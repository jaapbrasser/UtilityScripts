function AddDays (date, day) {
    var day = day * 86400000;
    return new Date(date.getTime()+day);
}
var CurrentDate = new Date();
console.log(AddDays(CurrentDate,1));
