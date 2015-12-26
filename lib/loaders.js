var utf = require('readutf');

exports.require = function(file, cb) {
  var contents = require(file);
  if (cb) {
    cb(null, contents);
  } else {
    return contents;
  }
};

exports.readFile = function(file, cb) {
  return cb ? utf.readFile(file, cb) : utf.readFileSync(file);
};
