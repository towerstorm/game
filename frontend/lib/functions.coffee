unless String::trim then String::trim = -> @replace /^\s+|\s+$/g, ""

window.humanizeWord = (name) ->
    words = name.match(/[A-Za-z][a-z]*/g);

    capitalize = (word) ->
        return word.charAt(0).toUpperCase() + word.substring(1);
        
    return words.map(capitalize).join(" ");

