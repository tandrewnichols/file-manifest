var gulp = require('gulp');
var rimraf = require('rimraf');

gulp.task('clean', function(cb) {
  rimraf('./coverage', cb);
});

