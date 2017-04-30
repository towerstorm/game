
functions =
  ucFirst: (str) =>
    str += '';
    f = str.charAt(0).toUpperCase();
    return f + str.substr(1);

module.exports = functions;

