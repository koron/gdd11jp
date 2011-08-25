(function() {
    var clickEvent = document.createEvent('MouseEvents');
    clickEvent.initEvent('click', false, true);

    var cards = [];
    for (var i = 0; i < 1024; ++i) {
        var element = document.getElementById('card' + i);
        if (element) {
            cards.push(element);
        } else {
            break;
        }
    }

    var colors = {};

    var max = cards.length;
    for (var i = 0; i < max; ++i) {
        var card1 = cards[i];
        card1.dispatchEvent(clickEvent);
        var color1 = card1.style.backgroundColor;

        var match1 = colors[color1];
        if (match1) {
            delete colors[color1];
            match1.dispatchEvent(clickEvent);
            continue;
        }

        var card2 = cards[i + 1];
        card2.dispatchEvent(clickEvent);
        var color2 = card2.style.backgroundColor;

        if (color1 == color2) {
            ++i;
            continue;
        } else {
            colors[color1] = card1;
        }
    }

    var s = '';
    for (var color in colors) {
        s += color + ':' + colors[color].id + '\n';
    }
    if (s.length > 0) {
        alert(s);
    }

})();
