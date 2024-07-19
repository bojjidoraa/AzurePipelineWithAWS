const { src, dest } = require('gulp');

function streamTask() {
  return src('*.js')
    .pipe(dest('output'));
}
gulp.task('sass', function () {
    return gulp.src('src/+(Feature|Foundation|Project)/*/code/Assets/Styling/*.scss')
        .pipe(gulp.dest('testFolder'))  //outputs file in destination folder
});

exports.default = streamTask;