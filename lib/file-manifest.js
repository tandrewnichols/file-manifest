var pedestrian = require('pedestrian');
var $ = require('varity');
var async = require('async');
var path = require('path');
var _ = require('lodash');
var fs = require('fs');

_.mixin(require('underscore.string'));

exports.generate = $('s+oa|s-ff', function(dir, options, patterns, reducer, callback) {
  options.patterns = options.patterns || patterns || '';
  options.patterns = _.isArray(options.patterns) || _.isEmpty(options.patterns) ? options.patterns : [options.patterns];
  options.dir = exports.resolve(dir);
  options.memo = options.memo || {};
  options.reducer = options.reducer || (exports.isAsync(callback) ? reducer : callback) || exports.reduce;
  options.require = typeof options.require === 'function' ? options.require : exports[options.require || 'require'];
  options.namer = options.namer || 'camelCase';
  return exports.run(options, callback);
});

exports.run = function(options, cb) {
  if (cb && options.reducer !== cb) {
    exports.collect(options, function(err, files) {
      async.reduce(files, options.memo, function(memo, file, next) {
        var basename = path.basename(file);
        var ext = path.extname(file);
        var fileObj = {
          relativePath: file.replace(options.dir + '/', ''),
          relativeName: file.replace(options.dir + '/', '').replace(ext, ''),
          fullPath: file,
          basename: basename,
          name: basename.replace(ext, ''),
          ext: ext
        };
        options.reducer(options, memo, fileObj, next);
      }, cb);
    });
  } else {
    return _.reduce(exports.collect(options), function(memo, file) {
      var basename = path.basename(file);
      var ext = path.extname(file);
      var fileObj = {
        relativePath: file.replace(options.dir + '/', ''),
        relativeName: file.replace(options.dir + '/', '').replace(ext, ''),
        fullPath: file,
        basename: basename,
        name: basename.replace(ext, ''),
        ext: ext
      };
      return options.reducer(options, memo, fileObj);
    }, options.memo);
  }
};


exports.resolve = function(dir) {
  if (dir.charAt(0) === '/') {
    return dir;
  } else {
    return path.resolve(dir);
  }
};

exports.isAsync = function(fn) {
  try {
    return /function\s*\(err/.test(fn.toString());
  } catch (e) {
    return false;
  }
};

exports.collect = function(options, cb) {
  if (cb) {
    pedestrian.walk(options.dir, options.patterns, cb);
  } else {
    return pedestrian.walk(options.dir, options.patterns);
  }
};

exports.reduce = function(options, manifest, file, cb) {
  var namer = typeof options.namer === 'function' ? options.namer : exports.namer;
  var key = namer(options, file);
  if (typeof cb === 'function') {
    options.require(options, file.fullPath, function(err, value) {
      manifest[key] = value;
      cb(null, manifest);
    });
  } else {
    manifest[key] = options.require(options, file.fullPath);
    return manifest;
  }
};

exports.require = function(options, file, cb) {
  if (cb) {
    cb(null, require(file));
  } else {
    return require(file);
  }
};

exports.readFile = function(options, file, cb) {
  if (cb) {
    fs.readFile(file, { encoding: 'utf8' }, cb);
  } else {
    return fs.readFileSync(file, { encoding: 'utf8' });
  }
};

exports.namer = function(options, file) {
  var fileParts = file.relativeName.split(/\W/g);
  return exports[options.namer](fileParts, options);
};

exports.camelCase = function(items, options) {
  return items.map(function(item, index) {
    return index ? _.capitalize(item) : item;
  }).join('');
};

exports.dash = function(items, options) {
  return items.join('-').toLowerCase();
};

exports.slash = function(items, options) {
  return items.join('/');
};

exports['class'] = function(items, options) {
  return items.map(_.capitalize).join('');
};

exports.lower = function(items, options) {
  return items.join('').toLowerCase();
};

exports.upper = function(items, options) {
  return items.join('').toUpperCase();
};

exports.underscore = exports.snake = function(items, options) {
  return items.join('_').toLowerCase();
};

exports.human = function(items, options) {
  var str = items.join(' ').toLowerCase();
  return str.charAt(0).toUpperCase() + str.slice(1);
};
