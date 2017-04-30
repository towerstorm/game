var gulp = require("gulp");
var less = require("gulp-less");
var minifyCss = require("gulp-minify-css");
var concat = require("gulp-concat");
var coffee = require("gulp-coffee");
var browserify = require("browserify");
var globify = require("require-globify");
var source = require("vinyl-source-stream");
var buffer = require("vinyl-buffer");
var del = require("del");
var rsync = require("gulp-rsync");
var runSequence = require("gulp-run-sequence");


gulp.task("styles", function() {
    return gulp.src([
        "css/*.less",
        "css/bootstrap.min.css"
        ], {cwd: "frontend"})
        .pipe(less())
        .pipe(minifyCss())
        .pipe(concat('frontend.css'))
        .pipe(gulp.dest("frontend/css"));
});

gulp.task("frontend", function() {
    return gulp.src([
        "lib/*.coffee",
        "models/*.coffee",
        "directives/**/*.coffee",
        "controllers/*.coffee",
        "filters/*.coffee",
        "services/*.coffee",
    ], {cwd: "frontend"})
    .pipe(coffee())
    .pipe(concat("frontend.js"))
    .pipe(gulp.dest("frontend/dist"));
});

gulp.task("vendor", function() {
    return gulp.src([
        'wheel-listener.js',
        'pinch-to-zoom.js',
        'analytics.min.js',
        'angular.js',
        'angular-animate.js',
        'angular-cookies.js',
        'angular-touch.js',
        'angular-route.js',
        'angular-resource.js',
        'ui-bootstrap-tpls.js',
        'pxloader.js',
        'pxloader-image.js',
        'lodash.js',
        'scrollglue.js',
        'screenfull.js',
        'keypress.min.js',
        'socket.io-client.min.js',
    ], {cwd: "frontend/vendor"})
    .pipe(concat("vendor.js"))
    .pipe(gulp.dest("frontend/dist"));
});

gulp.task("pixi", function() {
    return gulp.src([
      'pixi.dev-retina.js',
    ], {cwd: 'frontend/vendor'})
    .pipe(concat("pixi.js"))
    .pipe(gulp.dest("frontend/dist"));
});

gulp.task("dist", function() {
    gulp.start("styles", "frontend", "vendor", "pixi");
})
