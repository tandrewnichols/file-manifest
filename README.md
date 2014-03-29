[![Build Status](https://travis-ci.org/tandrewnichols/file-manifest.png)](https://travis-ci.org/tandrewnichols/file-manifest)

# File-Manifest

Require all the files in a directory into a single object

## Installation

`npm install file-manifest --save`

## Usage

File-manifest recursively requires everything in a given directory (optionally filtered with globstar patterns) and packages it into a single object where the keys are camel-cased file names. Thus if you had a directory called `foo`, whose structure looked like this:

```
bar
baz
  quux
  some-long-name
```

You'd end up with an object that looked like this:

```javascript
{
  fooBar: // foo/bar's exports
  fooBazQuux: //foo/baz/quux's exports
  fooBazSomeLongName: // foo/baz/some-long-name's exports
}
```

This is useful (for example) in an express app to create a route manifest:

```javascript
var routes = require('file-manifest').generate('routes');

app.get('/', routes.home);
app.get('/users/:id', routes.profile);
// etc.
```

or a middleware manifest:

```javascript
var middleware = require('file-manifest').generate('middleware');

app.use(middleware.setOriginPolicy);
app.use(middleware.defaultLogger);
// etc.
```

or in a mongoose app to load all models:

```javascript
var models = require('file-manifest').generate('models');
module.exports = function(req, res, next) {
  req.models = models;
  next();
};
```

### Sync

Demonstrated above, just call `.generate` with a relative or absolute path. As of version 0.0.4, file-manifest will convert a relative path to absolute one for you.

```javascript
var manifest = require('file-manifest').generate('some/dir');
```

### Async

Just like sync, but accepts a callback. It is important that the first argument to this function be `err` (more on this below).

```javascript
require('file-manifest').generate('some/dir', function(err, manifest) {
  // . . .
});
```

### With Patterns

Both sync and async versions accept a string pattern or list of string patterns to filter (see [minimatch](https://github.com/isaacs/minimatch) for more on globstar patterns).

```javascript
var manifest = require('file-manifest').generate('config', '**/*.json');

// or

require('file-manifest').generate('config', ['**/*.json', '**/*.yml'], function(err, manifest) {
  // . . .
});
```

### With a Custom Reduce

File-manifest also gives you the option to provide a custom reduce function. This let's you alter the behavior of file-manifest if simply requiring the files is insufficient (or you don't like camel-cased key names). This reduce function should accept the current manifest, the file currently being processed, and (for async implementations) a callback. If you're using the sync version, manipulate the manifest and return it. Otherwise, manipulate it and call the callback with an optional error and the manifest.

```javascript
var manifest = require('file-manifest').generate('partials', function(manifest, file) {
  var name = file.split('.')[0].split('/').join('-');
  manifest[name] = require(this.dir + '/' + file);
  return manifest;
});
```

The sync implemenation uses `_.reduce` ([underscore](http://underscorejs.org/)), while the async version uses `async.reduce` ([async](https://github.com/caolan/async)), so see those for more information. Inside the reduce function, you do have access to `this.dir`, which is the absolute version of the path passed in, and `this.patterns`, which is the original list of patterns.

You might have noted that the same `generate` function can take a reduce function, a callback, or both. The way `file-manifest` distinguishes is by examining the last function to see if it's first parameter is `err`. That's why all async implementations should pass a callback that accepts a variable named `err`.
