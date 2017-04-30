module.exports = {
    minionType: "land-drone",
    name: "Land Drone",
    description: "The droids secret super power",
    imageName: "land-drone.png",
    width: 48,
    height: 48,
    health: 360,
    speed: 25,
    value: 5,
    cost: 25,
    souls: 1,
    income: 0.2,
    moveType: "ground",
    frames: {
      down: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      right: [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
      up: [20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
      left: [30, 31, 32, 33, 34, 35, 36, 37, 38, 39],
    }
}