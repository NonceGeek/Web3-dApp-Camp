# 使用 React 开发 Dapp

webpack5 + react + tailwind + starcoin

![Demo图片](https://raw.github.com/LiuN1an/starcoin-test-dapp-react/main/IMG/demo.png?raw=true)

## 环境搭建

### 目录结构

大致目录结构如下:

```
- starcoin-test-dapp-react
    - src
        - app.jsx
        - index.jsx
        - index.html
    - package.json
```

### 安装 webpack

`npm i --save-dev webpack webpack-cli webpack-dev-server html-webpack-plugin @pmmmwh/react-refresh-webpack-plugin`

### 安装 babel

`npm i --save-dev babel-loader @babel/preset-env @babel/preset-react @babel/plugin-transform-runtime react-refresh @babel/plugin-proposal-decorators`

### 安装 tailwind 相关

`npm i --save-dev style-loader css-loader postcss-loader tailwindcss autoprefixer`

新建`postcss.config.js`，内容如下:

```js
module.exports = {
  plugins: [require("tailwindcss"), require("autoprefixer")],
};
```

新建`tailwind.config.js`，内容如下:

```js
module.exports = {
  purge: ["./src/**/*.jsx"], // 本目录结构在src下
  darkMode: false,
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [],
};
```

### 安装 react 以及 starcoin 相关

`npm i react react-dom classnames @starcoin/starcoin @starcoin/starmask-onboarding @ethersproject/bytes`

安装 starcoin 对应的本是 node 环境的一些 fallback

`npm i --save-dev util assert process stream-browserify browserify-zlib buffer`

### webpack 配置文件 `webpack.config.js`

```js
const path = require("path");
const webpack = require("webpack");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const ReactRefreshWebpackPlugin = require("@pmmmwh/react-refresh-webpack-plugin");
const tailwindcss = require("tailwindcss");
const autoprefixer = require("autoprefixer");

module.exports = {
  mode: "development",
  entry: "./src/index.jsx",
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "[name].bundle.js",
  },
  devtool: false,
  resolve: {
    extensions: ["*", ".jsx", ".js"],
    fallback: {
      util: require.resolve("util/"),
      assert: require.resolve("assert/"),
      process: require.resolve("process/browser"),
      stream: require.resolve("stream-browserify"),
      zlib: require.resolve("browserify-zlib"),
      buffer: require.resolve("buffer"),
    },
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: [
          {
            loader: require.resolve("babel-loader"),
            options: {
              presets: ["@babel/preset-env", "@babel/preset-react"],
              plugins: [
                "@babel/plugin-transform-runtime",
                require.resolve("react-refresh/babel"),
                ["@babel/plugin-proposal-decorators", { legacy: true }],
              ].filter(Boolean),
            },
          },
        ],
      },
      {
        test: /\.css$/,
        use: [
          "style-loader",
          { loader: "css-loader", options: { importLoaders: 1 } },
          {
            loader: "postcss-loader", // postcss loader needed for tailwindcss
            options: {
              postcssOptions: {
                ident: "postcss",
                plugins: [tailwindcss, autoprefixer],
              },
            },
          },
        ],
      },
  },
  plugins: [
    new webpack.ProvidePlugin({
      process: "process/browser",
      Buffer: ["buffer", "Buffer"],
    }),
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({
      template: "./src/index.html",
      inject: "head",
      hash: false,
    }),
    // 热更新
    new ReactRefreshWebpackPlugin(),
    new webpack.HotModuleReplacementPlugin(),
  ],
  devServer: {
    devMiddleware: {
      writeToDisk: true, // 可以注释掉，我这里只为能看清打包结果
    },
    hot: true,
    open: false,
    port: 3000,
    historyApiFallback: true,
  },
};
```

## 开发步骤

### starcoin
