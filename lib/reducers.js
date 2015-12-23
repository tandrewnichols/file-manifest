var _ = require('lodash');

exports._getVal = function(file, next, assign) {
  if (typeof next === 'function') {
    this.load.call(this, file, function(err, val) {
      next(err, assign(val));
    });
  } else {
    var val = this.load.call(this, file);
    return assign(val);
  }
};

exports.flat = function(manifest, file, next) {
  var key = this.name.call(this, file);
  return exports._getVal.call(this, file, next, function(val) {
    manifest[key] = val;
    return manifest;
  });
};

exports.nested = function(manifest, file, next) {
  var key = file.relative({ transform: 'dot' });
  return exports._getVal.call(this, file, next, function(val) {
    _.set(manifest, key, val);
    return manifest;
  });
};

exports.list = function(manifest, file, next) {
  var key = this.name.call(this, file);
  return exports._getVal.call(this, file, next, function(val) {
    manifest.push(val);
    return manifest;
  });
};

exports.objectList = function(manifest, file, next) {
  var key = file.relative({ ext: false });
  return exports._getVal.call(this, file, next, function(val) {
    manifest.push({
      name: key,
      contents: val
    });
    return manifest;
  });
};
