var gulp = require('gulp');
var config = require('./config');

gulp.task('watch', function() {
  gulp.watch(config.lib.concat(config.tests.unit).concat(config.tests.integration), ['unit', 'int']);
});

gulp.task('watch:unit', function() {
  gulp.watch(config.lib.concat(config.tests.unit), ['unit']);
});

gulp.task('watch:int', function() {
  gulp.watch(config.lib.concat(config.tests.integration), ['int']);
});

