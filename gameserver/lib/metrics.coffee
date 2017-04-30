
module.exports = {
  activeGames: {
    count: 0
    inc: -> @count++;
    dec: -> @count--;
  }
  lastGameStart: 0
};