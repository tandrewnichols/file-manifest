var pedestrian = require('pedestrian');
var $ = require('varity');
var async = require('async');
var path = require('path');
var _ = require('lodash');

_.mixin(require('underscore.string'));

var Manifest = function Manifest(dir, patterns) {
  this.dir = this.resolve(dir);
  this.patterns = patterns;
  _(this).bindAll('collect', 'reduce', 'require');
};

Manifest.prototype.resolve = function(dir) {
  if (dir.charAt(0) === '/') {
    return dir;
  } else {
    return path.resolve(dir);
  }
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
  var key = this.buildKey(file);
  manifest[key] = require(file); 
  return manifest;
};

Manifest.prototype.buildKey = function(file) {
  var filename = file.replace(this.dir + '/', '');
  return this.camelize(filename);
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
      reducer = callback;
      callback = null;
    }
    var reduce = reducer || manifest.reduce;
    if (callback) {
      manifest.collect(function(err, files) {
        async.reduce(files, {}, reduce.bind(manifest), callback);
      });
    } else {
      return _(manifest.collect()).reduce(reduce.bind(manifest), {});
    }
  })
};

