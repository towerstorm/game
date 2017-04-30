InjectedModifier = require("./injected.coffee")
GameEntity = require("../../entities/game-entity.coffee")

vfxConfig = require("config/vfx")
_ = require("lodash")

class TeleportModifier extends InjectedModifier
  name: "teleport"
  description: "Teleports enemies back {{distance}}m"
  distance: 0
  teleportDetails: null

  setup: (@distance) ->
    super(1)

  start: ->
    if !@minion
      return @end()
    super()
    @minion.setVisible(false)
    @minion.setVelocity(0, 0)
    @teleportDetails = @getTeleportDetails()

  ###
    Takes two node positions and a distance.
    Returns position distance away from startNode towards endNode
    If distance is greater than the distance between the two nodes returns null
  ###
  getPositionBetweenNodes: (startNode, endNode, distance) ->
    f = ts.game.functions
    if f.getDist(startNode, endNode) < distance
      return null
    angle = f.calcAngleInDegrees(startNode, endNode)
    return f.add(startNode, f.getDirectionVector(angle, distance))

  getTeleportDetails: ->
    if !@minion
      return false
    teleportDetails = {};
    totalDistance = 0
    currentPos = _.clone(@minion.pos)
    nodeId = _.clone(@minion.currentNode)
    nodePath = _.clone(@minion.nodePath)

    curNode = currentPos
    prevNodeId = Math.max(0, nodeId - 1) #Don't go below 0
    prevNode = ts.game.minionManager.getNodeScaled(nodePath, prevNodeId)
    distanceRemaining = @distance

    # Go from current node to each node before it until we get to the point between
    # nodes that we should be teleporting to.
    teleportPos = @getPositionBetweenNodes(curNode, prevNode, distanceRemaining)
    while teleportPos == null
      if prevNodeId == 0
        return {location: ts.game.minionManager.getNodeScaled(nodePath, 0), nextNodeId: 1}
      distanceRemaining -= ts.game.functions.getDist(curNode, prevNode)
      curNode = prevNode
      prevNodeId--
      prevNode = ts.game.minionManager.getNodeScaled(nodePath, prevNodeId)
      teleportPos = @getPositionBetweenNodes(curNode, prevNode, distanceRemaining)
    return {location: teleportPos, nextNodeId: prevNodeId + 1}







#        while totalDistance < @distance && nodeId > 0
#          nodeId--
#          node = ts.game.minionManager.getNodeScaled(nodePath, nodeId)
#          totalDistance += ts.game.functions.getDist(currentPos, node)
#          currentPos = node
#        if totalDistance < @distance #If we exited the above loop due to runnig out of nodes
#          teleportDetails.location = ts.game.minionManager.getNodeScaled(nodePath, 0)
#          teleportDetails.nextNodeId = 1
#        else
#          extraDistance = totalDistance - @distance
#          if nodeId == @minion.currentNode - 1 #If we're comparing with the last node we were at compare with minions pos rather than the node it's heading towards
#            nextNode = _.clone(@minion.pos)
#            teleportDetails.nextNodeId = null #Don't change the minions next node.
#          else
#            nextNode = ts.game.minionManager.getNodeScaled(nodePath, nodeId + 1)
#            teleportDetails.nextNodeId = nodeId + 1
#          if node.x == nextNode.x #Moving on y axis
#            xLocation = node.x
#            if node.y < nextNode.y
#              yLocation = node.y + extraDistance
#            else
#              yLocation = node.y - extraDistance
#          else
#            yLocation = node.y
#            if node.x < nextNode.x
#              xLocation = node.x + extraDistance
#            else
#              xLocation = node.x - extraDistance
#          teleportDetails.location = {x: xLocation, y: yLocation}
#        return teleportDetails

  spawnTeleportEffect: (x, y)->
    if ts.isHeadless
      return false
    item = vfxConfig.teleport
    ts.game.spawnEntity GameEntity.CTYPE.VFX, x, y, item

  end: ->
    if @minion
      newLoc = @teleportDetails.location
      nextNodeId = @teleportDetails.nextNodeId
      @minion.teleport(newLoc.x, newLoc.y)
      if nextNodeId?
        @minion.setTargetNode(nextNodeId)
      else
        @minion.setTargetNode(@minion.currentNode)
      minionCenter = @minion.getCenter()
      @spawnTeleportEffect(minionCenter.x, minionCenter.y)
      @minion.setVisible(true)
    super();

  reset: ->
    @distance = 0
    @teleportDetails = null
    super()

module.exports = TeleportModifier
