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
    extensions: ["*", ".ts", ".tsx", ".jsx", ".js", ".json", "svg"],
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
    ],
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
    new ReactRefreshWebpackPlugin(),
    new webpack.HotModuleReplacementPlugin(),
  ],
  devServer: {
    // devMiddleware: {
    //   writeToDisk: true,
    // },
    hot: true,
    open: false,
    port: 3000,
    historyApiFallback: true,
  },
};
