#!/usr/bin/env node

var fs         = require('fs');
var path       = require('path');
var uglifyjs   = require('uglify-js');
var browserify = require('browserify');
var banner     = fs.readFileSync(__dirname + '/../LICENSE').toString()
var name       = 'scent'
var src        = __dirname + '/../src';
var target     = __dirname + '/../lib';
var pkg        = require('../package.json');

function minify(source) {
  var opts = { fromString: true, mangle: {
    toplevel: true
  }};
  return uglifyjs.minify(source, opts).code;
}

var bannerLines = banner.split("\n");
for (var i = 0, ii = bannerLines.length; i < ii; i++) {
  bannerLines[i] = "* " + bannerLines[i]
};
bannerLines.unshift("/*");
bannerLines.push("* ", "* Version: "+pkg['version'], "*/", "");
banner = bannerLines.join("\n");

var writeOut = function (suffix, content, cb) {
  var fileName = path.resolve(target + '/' + suffix);
  fs.writeFile(fileName, content, function(err) {
    if (err) {
      console.log("Error while writing to: ", fileName);
      console.error(err.stack || err);
    }
    else {
      console.log('Written file '+fileName);
    }
    cb && cb();
  });
}

var async = require('async');
var coffee = require('coffee-script');

function compile(file, cb) {
  async.waterfall([
    function(next) {
      fs.readFile(src + '/' + file, next);
    },
    function(source, next) {
      try {
        var compiled = coffee.compile(source.toString(), {bare: true});
        writeOut(file.replace('.coffee', '.js'), compiled, next);
      }
      catch (e) {
        console.error('Failed compiling '+file);
        console.log(e);
      }
    }
  ], cb);
}

async.each(fs.readdirSync(src), compile, function(err) {
  if (err) {
    return console.error(err.stack || err);
  }

  var bundleOptions = {
    entries: target + '/' + name + '.js',
    basedir: '../',
    bundleExternal: false,
    standalone: name,
  };

  browserify(bundleOptions).bundle(function(err, buf) {
    if (err) {
      console.log("Error during bundling");
      return console.error(err.stack || err);
    }
    var out = buf.toString();
    writeOut(name + '-browser.js', banner + out);
    writeOut(name + '-browser.min.js', banner + minify(out));
  });
});
