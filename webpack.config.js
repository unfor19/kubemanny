const path = require('path');
const nodeExternals = require('webpack-node-externals');
const ZipPlugin = require('zip-webpack-plugin');

module.exports = {
    target: 'node',
    externals: [nodeExternals()],
    entry: './src/main.ts',
    node: {
        __filename: true,
        __dirname: true,
    },
    devtool: 'source-map',
    resolve: {
        extensions: ['.ts', '.js'],
    },
    module: {
        rules: [
            {
                test: /\.(ts|js)$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                },
            },
        ],
    },
    output: {
        filename: 'main.js',
        path: path.resolve(__dirname, 'dist'),
        libraryTarget: 'commonjs', // Kubeless needs this, otherwhise it cannot import the functions
    },
    plugins: [new ZipPlugin()],
};
