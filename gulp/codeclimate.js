var gulp = require('gulp');
var codeclimate = require('gulp-codeclimate-reporter');

gulp.task('codeclimate', function() {
  if (process.version.indexOf('v4') > -1) {
    gulp.src('coverage/lcov.info', { read: false })
      .pipe(codeclimate({
        token: '8abfd8828271583b9597891d0dfddb3cb9ca38cc1b0742fce4fe9af0c292ebc4'
      }));
  }
});

