// babel.config.js
module.exports = {
    plugins: ['@babel/plugin-transform-modules-commonjs', '@babel/plugin-transform-runtime'],
    presets: [['@babel/preset-env', { targets: { node: 12 }, module: 'commonjs' }], '@babel/preset-typescript'],
};
