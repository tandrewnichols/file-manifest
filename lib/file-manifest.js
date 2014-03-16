var pedestrian = require('./pedestrian'),
    $ = require('varity'),
    _ = require('underscore');

module.exports = {
  generate: $('s+a|[s]f', function(dir, patterns, fn) {
    var reducer = fn || function(memo, file) {
      var name = file.split('.')[0].split(/\W/g).map(function(item, index) {
       return index ? _(item).capitalize() : item;
      }).join('');
      memo[name] = require(dir + '/' + file);
      return memo;
    };
    return _(pedestrian.walk(dir, patterns)).reduce(reducer, {});
  })
};

