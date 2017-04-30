module.exports = {
    entry: "./game/index.js",
    output: {
        path: __dirname + "/frontend/dist",
        filename: "game.js"
    },
    module: {
      loaders: [
            { test: /\.coffee$/, loader: "coffee-loader" },
            { test: /\.(coffee\.md|litcoffee)$/, loader: "coffee-loader?literate" }
      ]
    },
    resolve: {
      modules: [
        "node_modules",
        __dirname
      ]
    }
};
