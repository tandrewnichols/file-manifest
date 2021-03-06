var pedestrian = require('pedestrian');
var async = require('async');
var path = require('path');
var _ = require('lodash');
var fs = require('fs');
var stack = require('stack-trace');
var loaders = require('./loaders');
var reducers = require('./reducers');
var Promise = require('promise');
var File = require('defiled');
var EventEmitter = require('events').EventEmitter;

/**
 * .generate
 *
 *  Asynchronously generate a manifest of files in from directory
 *
 *  @param {String} dir - The directory to load.
 *  @param {Object} [options] - Options.
 *  @param {String|Array} options.match - Globstar patterns to match when including files in
 *    (or excluding files from) the manifest
 *  @param {*} options.memo - Starting value for the manifest.
 *  @param {Function|String} options.load - Function for loading the file (e.g. require,
 *    fs.readFile) or string that maps to a provided loader
 *  @param {Function|String} options.name - Function for naming keys on the object or
 *    a string that maps to a provided namer
 *  @param {Function} options.reduce - A full replacement for the built-in reduce function
 *    if you need to REALLY custom things
 *  @param {Function|String} [callback] - An optional callback
 *
 *  @returns {Object} The manifest of files
 */
exports.generate = function(dir, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = null;
  }
  options = options || {};
  options.dir = exports.standardizePath(dir);
  options.match = _.isArray(options.match) || _.isEmpty(options.match) ? options.match : [options.match];
  options.memo = options.memo || (['list', 'objectList'].indexOf(options.reduce) > -1  ? [] : {});
  options.load = typeof options.load === 'function' ? options.load : exports.load(options.load);
  options.name = typeof options.name === 'function' ? options.name : exports.name(options.name);
  options.reduce = typeof options.reduce === 'function' ? options.reduce : exports.reduce(options.reduce);
  options.callback = callback;
  return exports.run(options);
};

/**
 * .generateSync
 *
 *  @param {String} dir - The directory to load.
 *  @param {Object} options - Options. Same as in .generate.
 *
 *  @returns {Object} The manifest of files.
 */
exports.generateSync = function(dir, options) {
  return exports.generate(dir, options);
};

/**
 * .generatePromise
 *
 *  Promise-based async implementation of .generate.
 *
 *  @param {String} dir - The directory to load.
 *  @param {Object} options - Options. Same as in .generate.
 *
 *  @returns {Promise} A promise object that will be resolved with the file manifest
 *    or rejected with an error
 */
exports.generatePromise = function(dir, options) {
  return new Promise(function(resolve, reject) {
    exports.generate(dir, options, function(err, manifest) {
      if (err) reject(err);
      else resolve(manifest);
    });
  });
};

/**
 * .generateEvent
 *
 *  Event-based async implementation of .generate.
 *
 *  @param {String} dir - The directory to load.
 *  @param {Object} options - Options. Same as in .generate.
 *
 *  @returns {EventEmitter} An event object that will fire a "manifest" event on success
 *    or an "error" event on an error
 */
exports.generateEvent = function(dir, options) {
  var emitter = new EventEmitter();
  exports.generate(dir, options, function(err, manifest) {
    if (err) emitter.emit('error', err);
    else emitter.emit('manifest', manifest);
  });
  return emitter;
};

/**
 * .standardizePath
 *
 *  Standardize the path passed to be absolute if it is not already
 *
 *  @param {string} dir - The directory to search
 *  @returns {string} The standardized path
 */
exports.standardizePath = function(dir) {
  if (dir.charAt(0) !== path.sep) {
    var trace = stack.get();
    var caller = _.find(trace, function(callsite) {
      var name = callsite.getFileName().split('/');
      return name[name.length - 1] !== 'file-manifest.js' && name.slice(-3).join('/') !== 'promise/lib/core.js';
    });
    dir = path.resolve(path.dirname(caller.getFileName()), dir);
  }
  return path.normalize(dir);
};

/**
 * .run
 *
 *  Get all the files in a directory and process them via reduce
 *
 *  @param {Object} options - The options
 *  @param {String|Array} options.match - Globstar patterns to match when including files in
 *    (or excluding files from) the manifest
 *  @param {*} options.memo - Starting value for the manifest.
 *  @param {Function|String} options.load - Function for loading the file (e.g. require,
 *    fs.readFile) or string that maps to a provided loader
 *  @param {Function|String} options.name - Function for naming keys on the object or
 *    a string that maps to a provided namer
 *  @param {Function} options.reduce - A full replacement for the built-in reduce function
 *    if you need to REALLY custom things
 *  @param {String} options.dir - The directory to search for files
 *  @param {Function} options.callback - The callback for asynchronous manifests
 *
 *  @returns {Object} The manifest of files
 */
exports.run = function(options) {
  var reduce = function(memo, file, next) {
    var fileObj = new File(file, options.dir);
    return options.reduce.call(options, memo, fileObj, next);
  };

  if (options.callback) {
    pedestrian.walk(options.dir, options.match || '', function(err, files) {
      if (err) options.callback(err);
      else async.reduce(files, options.memo, reduce, options.callback);
    });
  } else {
    return _.reduce(pedestrian.walk(options.dir, options.match || ''), reduce, options.memo);
  }
};

/**
 * .reduce
 *
 *  Generate a reduction function for processing files.
 *
 *  @param {String} [reduce] - If a string, this indicates a built-in reducer to use.
 *
 *  @returns {Function} Reduction function
 */
exports.reduce = function(reduce) {
  return function(manifest, file, next) {
    var reducer = reducers[reduce] || reducers[ exports._getDefaultReducer(this.memo) ];
    return reducer.call(this, manifest, file, next);
  };
};

/**
 * .name
 *  
 *  Generate a namer function for processed files.
 *
 *  @param {String} [name] - If a string, this indicates a built-in namer to use.
 *
 *  @returns {Function} Namer function
 */
exports.name = function(name) {
  return function(file) {
    var transformer = file.transformers[name] ? name : 'camel';
    return file.relative({ transform: transformer });
  };
};

/**
 * .load
 *
 *  Generate a loading function for processed files.
 *
 *  @param {String} [load] - If a string, this indicated a built-in loader to use.
 *
 *  @returns {Function} Loading function
 */
exports.load = function(load) {
  return function(file, cb) {
    var loader = loaders[load] || loaders[ exports._getDefaultLoader(file) ];
    return loader(file.abs(), cb);
  };
};

/**
 * ._getDefaultReducer
 *
 *  Choose a reducer based on the the memo.
 *
 *  @param {Object|Array|*} memo - The memo for the reduction
 *
 *  @returns {String} One of "list" and "flat"
 */
exports._getDefaultReducer = function(memo) {
  // If memo is an array, use the "list" reducer,
  // otherwise, use the "flat" reducer.
  if (_.isArray(memo)) {
    return 'list';
  } else {
    return 'flat';
  }
};

/**
 * ._getDefaultLoader
 *
 *  Choose a loader based on whether the file is requirable and whether we're sync or async
 *
 *  @param {File} file - The file to load
 *  @param {Function} [cb] - An optional callback (for determining sync/async)
 *
 *  @returns {String} One of "require" and "readFile"
 */
exports._getDefaultLoader = function(file) {
  var ext = file.ext();
  // If the file can be loaded via require, make that the default,
  // otherwise, use readFile.
  if (ext === '.js' || ext === '.json') {
    return 'require';
  } else {
    return 'readFile';
  }
};
