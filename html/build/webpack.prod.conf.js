'use strict'
const path = require('path')
const utils = require('./utils') // 请确认你有这个工具模块，用来生成 style loaders 与路径等
const webpack = require('webpack')
const config = require('../config') // 读取 config 中的 build 配置（例如 assetsRoot、assetsSubDirectory、productionSourceMap 等）
const merge = require('webpack-merge') // 使用旧版的 webpack-merge（与 webpack 3 相容）
const baseWebpackConfig = require('./webpack.base.conf')

// 插件
const CopyWebpackPlugin = require('copy-webpack-plugin')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const ExtractTextPlugin = require('extract-text-webpack-plugin')

const webpackConfig = merge(baseWebpackConfig, {
  module: {
    rules: utils.styleLoaders({
      sourceMap: config.build.productionSourceMap,
      extract: true,       // 表示提取 CSS
      usePostCSS: true
    })
  },
  // 如果需要 source map 就用配置中的 devtool，否则设为 false
  devtool: config.build.productionSourceMap ? config.build.devtool : false,
  output: {
    path: config.build.assetsRoot, // 比如 config.build.assetsRoot = path.resolve(__dirname, '../dist')
    filename: utils.assetsPath('js/[name].[chunkhash].js'),
    chunkFilename: utils.assetsPath('js/[id].[chunkhash].js')
  },
  plugins: [
    // 定义环境变量
    new webpack.DefinePlugin({
      'process.env': config.build.env // 例如 require('../config/prod.env')
    }),
    // JS 压缩：webpack 3 中用 UglifyJsPlugin
    new webpack.optimize.UglifyJsPlugin({
      compress: {
        warnings: false
      },
      sourceMap: config.build.productionSourceMap
    }),
    // 提取 CSS 到独立文件（使用 extract-text-webpack-plugin）
    new ExtractTextPlugin({
      filename: utils.assetsPath('css/[name].[contenthash].css'),
      allChunks: true
    }),
    // 自动生成 index.html 并注入资源
    new HtmlWebpackPlugin({
      filename: config.build.index, // 输出到 config.build.index 所指定的路径（通常是 dist/index.html）
      template: 'index.html',         // 使用项目根目录下的 index.html 作为模板
      inject: true,
      minify: {
        removeComments: true,
        collapseWhitespace: true,
        removeAttributeQuotes: true
      },
      chunksSortMode: 'dependency'
    }),
    // 提取第三方库至 vendor.js
    new webpack.optimize.CommonsChunkPlugin({
      name: 'vendor',
      minChunks(module) {
        // 这里判断是否来自 node_modules
        return (
          module.resource &&
          /\.js$/.test(module.resource) &&
          module.resource.indexOf(path.join(__dirname, '../node_modules')) === 0
        )
      }
    }),
    // 提取 webpack runtime 及 manifest 到 manifest.js 中
    new webpack.optimize.CommonsChunkPlugin({
      name: 'manifest',
      minChunks: Infinity
    }),
    // 拷贝 static 资料夹到指定目录
    new CopyWebpackPlugin([
      {
        from: path.resolve(__dirname, '../static'),
        to: config.build.assetsSubDirectory, // 例如 'static'
        ignore: ['.*']
      }
    ])
  ]
})

// 若需要 gzip 压缩（可选）
if (config.build.productionGzip) {
  const CompressionWebpackPlugin = require('compression-webpack-plugin')
  webpackConfig.plugins.push(
    new CompressionWebpackPlugin({
      asset: '[path].gz[query]',
      algorithm: 'gzip',
      test: new RegExp(
        '\\.(' + config.build.productionGzipExtensions.join('|') + ')$'
      ),
      threshold: 10240,
      minRatio: 0.8
    })
  )
}

// 若需要 bundle analyzer 报告（可选）
if (config.build.bundleAnalyzerReport) {
  const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
  webpackConfig.plugins.push(new BundleAnalyzerPlugin())
}

module.exports = webpackConfig
