module.exports = {
    minionType: "sky-drone",
    name: "Sky Drone",
    description: "Rules the skys for the droids. ",
    imageName: "sky-drone.png",
    width: 32,
    height: 32,
    health: 960,
    speed: 15,
    value: 10,
    cost: 50,
    souls: 1,
    income: 0.4,
    moveType: "air",
    frames: {
      down: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      right: [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
      up: [20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
      left: [30, 31, 32, 33, 34, 35, 36, 37, 38, 39],
    },
    zIndex: 21
}