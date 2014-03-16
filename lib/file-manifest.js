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
  _(this).bindAll('collect', 'reduce', 'require');
};

util.inherits(Manifest, events.EventEmitter);

Manifest.prototype.collect = function(cb) {
  var self = this;
  if (cb) pedestrian.walk(self.dir, self.patterns, cb);
  else return pedestrian.walk(self.dir, self.patterns);
};

Manifest.prototype.reduce = function(manifest, file, cb) {
  if (typeof cb === 'function') {
    if (!this.emit('file', manifest, file, cb)) {
      cb(null, this.require(manifest, file));
    } else {
      cb(null, manifest);
    }
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
  generate: $('s+a|[s]+of', function(dir, patterns, opts, fn) {
    var manifest = new Manifest(dir, patterns);
    if (!_(opts).isEmpty()) {
      var reducer = opts.reduce || manifest.reduce;
      manifest.collect(function(err, files) {
        async.reduce(files, {}, reducer, function(err, fileManifest) {
          if (err) {
            if (fn) fn(err, null);
            else manifest.emit('error', err);
          } else {
            if (fn) fn(null, fileManifest);
            else manifest.emit('manifest', fileManifest);
          }
        });
      });
    } else {
      var reducer = fn || manifest.reduce;
      return _(manifest.collect()).reduce(reducer, {});
    }
  })
};

