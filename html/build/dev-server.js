'use strict'
require('./check-versions')()

const config = require('../config')


const opn = require('opn')
const path = require('path')
const express = require('express')
const webpack = require('webpack')
const proxyMiddleware = require('http-proxy-middleware')
const webpackConfig = require('./webpack.dev.conf')

const port = process.env.PORT || config.dev.port
const autoOpenBrowser = !!config.dev.autoOpenBrowser
const proxyTable = config.dev.proxyTable

const app = express()
console.log('Creating webpack compiler...')
const compiler = webpack(webpackConfig)

const devMiddleware = require('webpack-dev-middleware')(compiler, {
  publicPath: webpackConfig.output.publicPath,
  quiet: false
})

const hotMiddleware = require('webpack-hot-middleware')(compiler, {
  log: console.log,
  heartbeat: 2000
})

// force page reload when html-webpack-plugin template changes
compiler.plugin('compilation', function (compilation) {
  console.log('Webpack compilation started')
  compilation.plugin('html-webpack-plugin-after-emit', function (data, cb) {
    console.log('HTML plugin emit completed')
    hotMiddleware.publish({ action: 'reload' })
    if (cb) cb()
  })
})

// proxy api requests
Object.keys(proxyTable).forEach(function (context) {
  let options = proxyTable[context]
  if (typeof options === 'string') {
    options = { target: options }
  }
  app.use(proxyMiddleware(options.filter || context, options))
})

// handle fallback for HTML5 history API
app.use(require('connect-history-api-fallback')())

// serve webpack bundle output
app.use(devMiddleware)

// enable hot-reload and state-preserving
// compilation error display
app.use(hotMiddleware)

// serve pure static assets
const staticPath = path.posix.join(config.dev.assetsPublicPath, config.dev.assetsSubDirectory)
app.use(staticPath, express.static('./static'))

const uri = 'http://localhost:' + port

console.log('> Starting dev server...')

compiler.plugin('done', stats => {
  console.log('Webpack compilation completed')
  if (stats.hasErrors()) {
    console.log('error:')
    console.log(stats.toString({
      chunks: false,
      colors: true
    }))
    return
  }
  
  console.log('Compilation successful')
})

devMiddleware.waitUntilValid(() => {
  console.log('> Listening at ' + uri + '\n')
  
  if (autoOpenBrowser && process.env.NODE_ENV !== 'testing') {
    opn(uri)
  }
  
  const server = app.listen(port, err => {
    if (err) {
      console.error('Server start failed:', err)
      return
    }
    console.log('Server started successfully on port', port)
  })
})

module.exports = {
  close: () => {
    server.close()
  }
}