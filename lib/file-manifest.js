var pedestrian = require('./pedestrian'),
    $ = require('varity'),
    async = require('async'),
    _ = require('underscore');

var Manifest = function Manifest(dir, patterns) {
  this.dir = dir;
  this.patterns = patterns;
  _(this).bindAll('collect', 'reduce', 'require');
};


Manifest.prototype.isAsync = function(fn) {
  try {
    return /function\s*\(err/.test(fn.toString());
  } catch (e) {
    return false;
  }
};

Manifest.prototype.collect = function(cb) {
  var self = this;
  if (cb) pedestrian.walk(self.dir, self.patterns, cb);
  else return pedestrian.walk(self.dir, self.patterns);
};

Manifest.prototype.reduce = function(manifest, file, cb) {
  if (typeof cb === 'function') {
    cb(null, this.require(manifest, file));
  } else {
    return this.require(manifest, file);
  }
};

Manifest.prototype.require = function(manifest, file) {
  manifest[this.camelize(file)] = require(this.dir + '/' + file); 
  return manifest;
};

Manifest.prototype.camelize = function(file) {
  return file.split('.')[0].split(/\W/g).map(function(item, index) {
    return index ? _(item).capitalize() : item;
  }).join('');
};


module.exports = {
  generate: $('s+a|[s]-ff', function(dir, patterns, reducer, callback) {
    var manifest = new Manifest(dir, patterns);
    if (!manifest.isAsync(callback)) {
      reducer = callback, callback = null;
    }
    if (callback) {
      var reduce = reducer || manifest.reduce;
      manifest.collect(function(err, files) {
        async.reduce(files, {}, reduce.bind(manifest), callback);
      });
    } else {
      var reduce = reducer || manifest.reduce;
      return _(manifest.collect()).reduce(reduce.bind(manifest), {});
    }
  })
};

