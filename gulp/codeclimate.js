var gulp = require('gulp');
var codeclimate = require('gulp-codeclimate-reporter');

gulp.task('codeclimate', function() {
  if (process.version.indexOf('v4') > -1) {
    gulp.src('coverage/lcov.info', { read: false })
      .pipe(codeclimate({
        token: '99f4948db226295b48a68e6af252825ec12bae5ad6f59ff4b224f345b7c10772'
      }));
  }
});

