var tsCookie;

tsCookie = function(key, value, options) {
  var days, decode, result, t;
  if (arguments.length > 1 && String(value) !== "[object Object]") {
    options = options || {};
    if (value === null || value === undefined) {
      options.expires = -1;
    }
    if (typeof options.expires === "number") {
      days = options.expires;
      t = options.expires = new Date();
      t.setDate(t.getDate() + days);
    }
    value = String(value);
    return (document.cookie = [encodeURIComponent(key), "=", (options.raw ? value : encodeURIComponent(value)), (options.expires ? "; expires=" + options.expires.toUTCString() : ""), (options.path ? "; path=" + options.path : ""), (options.domain ? "; domain=" + options.domain : ""), (options.secure ? "; secure" : "")].join(""));
  }
  options = value || {};
  result = void 0;
  decode = (options.raw ? function(s) {
    return s;
  } : decodeURIComponent);
  if ((result = new RegExp("(?:^|; )" + encodeURIComponent(key) + "=([^;]*)").exec(document.cookie))) {
    return decode(result[1]);
  } else {
    return null;
  }
};

if (typeof window !== "undefined" && window !== null) {
  window.tsCookie = tsCookie;
} else {
  module.exports = tsCookie;
}
