#!/usr/bin/env node

var fs         = require('fs');
var path       = require('path');
var banner     = fs.readFileSync(__dirname + '/../LICENSE').toString()
var src        = __dirname + '/../src';
var lib        = __dirname + '/../lib';
var pkg		   = require('../package.json');

var bannerLines = banner.split("\n");
for (var i = 0, ii = bannerLines.length; i < ii; i++) {
  bannerLines[i] = "* " + bannerLines[i]
};
bannerLines.unshift("/*");
bannerLines.push("* ", "* Version: "+pkg['version'], "*/", "");
banner = bannerLines.join("\n");

var coffee = require('coffee-script');
function compile(file) {
	var compiled = coffee.compile(fs.readFileSync(src + '/' + file).toString(), {
  		bare: true
	});
	var out = lib + '/' + file.replace('.coffee', '.js')
	fs.writeFileSync(out, banner + compiled);
	console.log("written file "+out);
}

fs.readdirSync(src).forEach(compile);
