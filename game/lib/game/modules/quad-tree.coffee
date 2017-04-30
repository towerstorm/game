###
  Kind of a QuadTree but not really. Basically breaks the battlefield up into
  chunks so that when a tower has to find new targets it only compares its position
  with nearby minions, not every single minion on the battlefield
###
class QuadTree
  
  constructor: (gameScale) ->
    @leaves = []
    @leafSize = 2
    @leafSizeScaled = @leafSize * gameScale

  getLeaf: (xPos, yPos) ->
    leafX = Math.floor(xPos / @leafSizeScaled);
    leafY = Math.floor(yPos / @leafSizeScaled);
    if !@leaves[leafX]?
      @leaves[leafX] = []
    if !@leaves[leafX][leafY]?
      @leaves[leafX][leafY] = []

    return @leaves[leafX][leafY];

  buildTree: (entities) ->
    @leaves = []
    for entity in entities
      @addEntity(entity)

  addEntity: (entity) ->
    @getLeaf(entity.pos.x, entity.pos.y).push(entity)

  removeEntity: (entity) ->
    @getLeaf(entity.pos.x, entity.pos.y).eraseSingle(entity)


  ###
    Gets all minions in all the leaves that this tower can reach
  ###
  getEntities: (xPos, yPos, rangeScaled) ->
    startX = Math.floor((xPos - rangeScaled) / @leafSizeScaled);
    if startX < 0 then startX = 0
    endX = Math.floor((xPos + rangeScaled) / @leafSizeScaled);

    startY = Math.floor((yPos - rangeScaled) / @leafSizeScaled);
    if startY < 0 then startY = 0
    endY = Math.floor((yPos + rangeScaled) / @leafSizeScaled);

    entities = []
    for x in [startX..endX]
      for y in [startY..endY]
        if @leaves[x]? && @leaves[x][y]?
          entities = entities.concat(@leaves[x][y])
    return entities

module.exports = QuadTree
