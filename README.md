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
  fooBar: 'foo/bar exports',
  fooBazQuux: 'foo/baz/quux exports',
  fooBazSomeLongName: 'foo/baz/some-long-name exports'
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

A string or array of string globstar patterns to filter which files to parse. (See [minimatch](https://github.com/isaacs/minimatch) for pattern syntax.)

###### memo

The starting value for the manifest reduction. By default, this is `{}` (except in a couple cases defined below), but you can use a different starting value, so long as it is compatible with the reduction (that is, `'string'.push()` is going to blow up).

###### name

A function that takes a [file object](https://github.com/tandrewnichols/defiled#api) and returns the name of the key to be used for this file. _Or_ a string that points to a built-in namer function (see the [list of transformers defiled exposed](https://github.com/tandrewnichols/defiled#filerelative)). By default, camel casing is used for key names. For example, setting name to "dash" will return dash delimited file names like `foo-bar-baz` instead of camel cased ones.

###### load

A function that loads the value of the key defined above. The default is `require` for files that can be required (`.js` and `.json`) and `readFile` for other files. You can pass any function that accepts a file path (absolute) and an optional callback. For instance, you could pass `require('yamljs').load` to parse yaml files. Load can also be a string pointing at a built-in loader: one of `"readFile"` or `"require"`. You probably won't need this, since the correct one is chosen dynamically, but if you want to read javascript without loading it as source, or if you want to load a coffeescript file and you've previously called required `coffee-script/register`, then you may want to do this.

###### reduce

A custom reduce function for creating the manifest. In asynchronous implementations, this uses [async.js's reduce](https://github.com/caolan/async#reducearr-memo-iterator-callback), and in sync implementations, it uses [lodash's reduce](https://lodash.com/docs#reduce). That is, you can pass an async reducer with the signature `function(manifest, file, next)` where `next` is a callback with the signature `function(err, reduction)` or a sync reducer with the signature `function(manifest, file[, index][, collection])` that returns the reduction. In both cases, the `file` parameter is a [file object](https://github.com/tandrewnichols/defiled). The reduce function will be called with the options object as the (`this`) context, so you can either calculate the key and value yourself or call `this.name.call(this, file)` and `this.load.call(this, file[, callback])` to get them.

Additionally, `reduce` can be a string pointing at a custom reducer. The default is `"flat"`, which returns a single-level object of properties with their exports, but you can also pass `"nested"`, `"list"`, or `"objectList"`. Given the example "foo" directory above, the results would be as follows:

```js
// flat (default)
{
  fooBar: 'foo/bar exports',
  fooBazQuux: 'foo/baz/quux exports',
  fooBazSomeLongName: 'foo/baz/some-long-name exports'
}

// nested
{
  foo: {
    bar: 'foo/bar exports'
    baz: {
      quux: 'foo/baz/quux exports',
      someLongName: 'foo/baz/some-long-name exports'
    }
  }
}

// list
[
  'foo/bar exports',
  'foo/baz/quux exports',
  'foo/baz/some-long-name exports'
]

// objectList
[
  {
    name: 'foo/bar',
    contents: 'foo/bar exports'
  },
  {
    name: 'foo/baz/quux',
    contents: 'foo/baz/quux exports'
  },
  {
    name: 'foo/baz/some-long-name',
    contents: 'foo/baz/some-long-name exports'
  }
]
```

Some of this is handled smartly for you. For instance, if you set memo to `[]` in the options hash, reduce will automatically be set to "list." Similarly, if you set reduce to "list" or "objectList," memo will be set to `[]`.

#### .generateSync(directory[, options])

This is just syntactic sugar for calling `.generate` without a function. It doesn't do anything that `.generate` doesn't; it's provided only for completeness and for those who like having "sync" in their synchronous function names.

#### .generatePromise(directory[, options])

An asynchronous implementation that returns a promise instead.

#### .generateEvent(directory[, options])

An asynchronous implementation that returns an event emitter instead.

## Examples

Given `var fm = require('file-manifest');`:

Get all routes synchronously:

```js
var routes = fm.generate('routes');
```

Get all member routes:

```js
var routes = fm.generate('routes', { match: '**/*member*.js' });
```

Get all routes _except_ index.js:

```js
var routes = fm.generate('routes', { match: ['**/*.js', '!index.js'] }
```

Get all routes with dashed names:

```js
var routes = fm.generate('routes', { name: 'dash' });
```

Get all routes with a random name:

```js
var routes = fm.generate('routes', { name: require('uuid').v4 });

// or
var routes = fm.generate('routes', { name: require('randomstring').generate });
```

Get all markdowns files in the current directory (as strings using "readFile")

```js
var routes = fm.generate('./', { load: "readFile" }); // not necessary, since this is the default for none .js/.json files
```

Get all markdown file in the current directory as markdown:

```js
var routes = fm.generate('./', { load: require('marky-mark').parseFileSync });
```

Get a list of routes:

```js
var routes = fm.generate('routes', { reduce: 'list' });

// or
var routes = fm.generate('routes', { memo: [] });
```

Get a list of routes that includes the file names:

```js
var routes = fm.generate('routes', { reduce: 'objectList' });
```

Get a nested object of routes:

```js
var routes = fm.generate('routes', { reduce: 'nested' });
```

Get all files in lib grouped by extension

```js
var routes = fm.generate('lib', {
  reduce: function(manifest, file) {
    var key = file.ext().replace('.', '');
    manifest[key] = manifest[key] || [];
    manifest[key].push(file.relative({ ext: false }));
    return manifest;
  }
});
```

Get all routes asynchronously:

```js
fm.generate('routes', function(err, routes) {

});
```

Get all routes with a promise:

```js
var promise = fm.generatePromise('routes');
promise.then(function(routes) {

}, function(error) {

});
```

Get all routes via event:

```js
var emitter = fm.generateEvent('routes');
emitter.on('manifest', function(routes) {

}).on('error', function(error) {

});
```

## Contributing

Please see [the contribution guidelines](CONTRIBUTING.md).
