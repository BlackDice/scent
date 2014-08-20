#!/usr/bin/env node

var fs         = require('fs');
var path       = require('path');
var uglifyjs   = require('uglify-js');
var banner     = fs.readFileSync(__dirname + '/../LICENSE').toString()
var src        = __dirname + '/../src/scent.coffee';

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
bannerLines.push("*/", "");
banner = bannerLines.join("\n");

var coffee = require('coffee-script');
var compiled = coffee.compile(fs.readFileSync(src).toString(), {
  bare: true
});

var minified = minify(compiled);

fs.writeFileSync(__dirname + '/../lib/scent.js', banner + compiled);
fs.writeFileSync(__dirname + '/../lib/scent.min.js', banner + minified);
