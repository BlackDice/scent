var webpack = require('webpack');

module.exports = {
	entry: {
		bundle: './test/index.coffee',
	},
	output: {
		path: __dirname + '/test/out',
		filename: "[name].js",
		pathinfo: true,
	},
	module: {
		loaders: [
			{ test: /\.coffee$/, loader: "babel!coffee" },
		],
	},
	devtool: 'inline-source-map',
	resolve: {
		extensions: ['', '.coffee', '.js'],
	},
	plugins: [
		new webpack.DefinePlugin({
			'IN_TEST': JSON.stringify('test')
		}),
		new webpack.ProvidePlugin({
			'Scent': '../src/scent.coffee'
		}),
	]
}
