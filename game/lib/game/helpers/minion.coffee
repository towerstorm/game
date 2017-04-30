
_ = require("lodash")

minionHelpers = {
  
  getCostOfCheapestMinion: (minions) ->
    return Math.min.apply(null, _.map(minions, 'cost'))
      
       
    
  getRandomMinion: (tick, seed, minions, maxCost) ->
    validMinions = _.filter(minions, (minion) -> return minion.cost <= maxCost)
    minionNum = Math.floor((tick * seed) % validMinions.length)
    return _.cloneDeep(validMinions[minionNum])
  
  
}

module.exports = minionHelpers