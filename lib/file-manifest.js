var pedestrian = require('./pedestrian'),
    $ = require('varity'),
    util = require('util'),
    events = require('events'),
    async = require('async'),
    _ = require('underscore');

var Manifest = function Manifest(dir, patterns) {
  events.EventEmitter.call(this);
  this.dir = dir;
  this.patterns = patterns;
};

util.inherits(Manifest, events.EventEmitter);

Manifest.prototype.collect = function(cb) {
  var self = this;
  if (cb) pedestrian.walk(self.dir, self.patterns, cb);
  else return pedestrian.walk(self.dir, self.patterns);
};

Manifest.prototype.reduce = function(manifest, file, cb) {
  if (cb) {
    if (!this.emit('file', manifest, file, cb)) {
      manifest[file.split('.')[0].camelize()] = require(dir + '/' + file); 
      cb(manifest);
    }
  } else {
    manifest[file.split('.')[0].camelize()] = require(dir + '/' + file); 
    return manifest;
  }
};

module.exports = {
  generate: $('s+a|[s]+bf', function(dir, patterns, async, fn) {
    var manifest = new Manifest(dir, patterns);
    if (async) {
      manifest.collect(function(err, files) {
        async.reduce(files, {}, manfiest.reduce, function(err, fileManifest) {
          if (err) {
            if (fn) fn(err, null);
            else manifest.emit('error', err);
          } else {
            if (fn) fn(null, fileManifest);
            else manfiest.emit('manifest', fileManifest);
          }
        });
      });
    } else {
      var reducer = fn || manifest.reduce;
      return _(manifest.collect(dir, patterns)).reduce(reducer, {});
    }
  })
};

