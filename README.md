[![Build Status](https://travis-ci.org/mantacode/file-manifest.png)](https://travis-ci.org/mantacode/file-manifest) [![downloads](http://img.shields.io/npm/dm/file-manifest.svg)](https://npmjs.org/package/file-manifest) [![npm](http://img.shields.io/npm/v/file-manifest.svg)](https://npmjs.org/package/file-manifest) [![Code Climate](https://codeclimate.com/github/mantacode/file-manifest/badges/gpa.svg)](https://codeclimate.com/github/mantacode/file-manifest) [![Test Coverage](https://codeclimate.com/github/mantacode/file-manifest/badges/coverage.svg)](https://codeclimate.com/github/mantacode/file-manifest) [![dependencies](https://david-dm.org/mantacode/file-manifest.png)](https://david-dm.org/mantacode/file-manifest)

# File-Manifest

Require all the files in a directory into a single object

## Installation

`npm install file-manifest --save`

## Usage

File-manifest recursively requires everything in a given directory (optionally filtered with globstar patterns) and packages it into a single object where the keys are (by default) camel-cased file names. Thus if you had a directory called `foo`, whose structure looked like this:

```
bar
baz
  quux
  some-long-name
```

You'd end up with an object that looked like this:

```js
{
  fooBar: // foo/bar's exports
  fooBazQuux: // foo/baz/quux's exports
  fooBazSomeLongName: // foo/baz/some-long-name's exports
}
```

This is useful (for example) in an express app to create a route manifest:

```js
var routes = require('file-manifest').generate('routes');

app.get('/', routes.home);
app.get('/users/:id', routes.profile);
// etc.
```

or a middleware manifest:

```js
var middleware = require('file-manifest').generate('middleware');

app.use(middleware.setOriginPolicy);
app.use(middleware.defaultLogger);
// etc.
```

or in a mongoose app to load all models:

```js
var models = require('file-manifest').generate('models');
module.exports = function(req, res, next) {
  req.models = models;
  next();
};
```

## API

#### .generate(directory[, options][, callback])

The main entry point for the library. If a callback is passed (signature `function(error, manifest)`), file-manifest will treat this is as an asynchronous call and return the results in the callback. The possible options are:

###### match

A string or array of string globstar patterns to filter which files to parse. (See [minimatch](https://github.com/isaacs/minimatch) for pattern syntax)

###### memo

The starting value for the manifest reduction. By default, this is `{}` (except in a couple cases defined below), but you can use a different starting value, so long as it is compatible with the reduction (that is, `'string'.push()` is going to blow up).

###### name

A function that takes a [file object](https://github.com/tandrewnichols/defiled#api) and returns the name of the key to be used for this file. _Or_ a string that points to a built-in namer function (see the [list of transformers defiled exposed](https://github.com/tandrewnichols/defiled#filerelative). By default, camel casing is used for key names.

###### load

A function that loads the value of the key defined above. The default is `require` for files that can be required (`.js` and `.json`) and `readFile` for other files. You can pass any function that accepts a file path (absolute) and an optional callback. For instance, you could pass `require('yamljs').load` to parse yaml files.

###### reduce

A custom reduce function for creating the manifest. In asynchronous implementations, this uses [async.js's reduce](https://github.com/caolan/async#reducearr-memo-iterator-callback), and in sync implementations, it uses [lodash's reduce](https://lodash.com/docs#reduce). That is, you can pass an async reducer with the signature `function(manifest, file, next)` where `next` is a callback with the signature `function(err, reduction)` or a sync reducer with the signature `function(manifest, file, [index], [collection])` that returns the reduction. In both cases, the `file` parameter is an instance of a [defiled object](https://github.com/tandrewnichols/defiled). The reduce function will be called with the options object as the (`this`) context, so you can either calculate the key and value yourself or call `this.name.call(this, file)` and `this.load.call(this, file)` (or `this.load.call(this, file, function() { // callback })`) to get them.

#### .generateSync(directory[, options])

This is just syntactic sugar for calling `.generate` without a function. It doesn't do anything that `.generate` doesn't; it's provided only for completeness and for those who like having "sync" in their synchronous function names.

#### .generatePromise(directory[, options])

An asynchronous implementation that returns a promise instead.

#### .generateEvent(directory[, options])

An asynchronous implementation that returns an event emitter instead.

## Examples
