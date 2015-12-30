var webpack = require('webpack');

module.exports = {
	entry: {
		scent: './lib/scent.js',
	},
	output: {
		path: __dirname + '/dist',
		filename: "[name].js",
		library: 'Scent',
		libraryTarget: 'umd',
		umdNamedDefine: true,
	},
	devtool: 'source-map',
	plugins: [
		new webpack.optimize.OccurenceOrderPlugin(),
		new webpack.BannerPlugin(require('fs').readFileSync('LICENSE', 'utf8')),
		new webpack.optimize.UglifyJsPlugin({
			compress: { warnings: false }
		}),
	]
}
