KEY = require("../../engine/keys.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")

_ = require("lodash")

class TutorialManager
  
  constructor: ->
    @reset()

  begin: ->
    if ts.game.settings.mode != config.modes.tutorial
      return false
    if ts.input?
      ts.input.bind(KEY.N, "nextTutorialStep")
    @initSteps();
    @startStep(0);

  reset: ->
    @currentStep = 0
    @inputPressed = false
    @steps = null
    @completeListener = null
    if @completeTimeout
      clearTimeout(@completeTimeout)
    @completeTimeout = null
    @reverseListener = null
    @opponentId = "opponent"
    @freePlayStarted = false
    @lastTick = null
    @visibleTowers = []
    @visibleMinions = []

  initSteps: ->
    @steps = [
      {
        id: 'Select Tower'
        text: {
          title: "Click on a tower in the side bar to select it."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "tower"
            buttonSubType: "crossbow"
          }
        }
        action: {
          type: "createPlayer"
          details: {
          }
        }
        complete: {
          message: gameMsg.pickedTower
          params: ["crossbow"]
        }
      }
      {
        id: 'Build Tower'
        text: {
          title: "Click on the battlefield to place the tower"
        }
        highlight: {
          type: "position"
          details: {x: 3, y: 6}
        }
        complete: {
          message: gameMsg.clickPlaceTower
          params: [3, 6]
        }
        reverse: {
          message: gameMsg.pickedTower
          params: [false]
        }
      }
      {
        id: 'Created Tower'
        highlight: {
          type: "position"
          details: {x: 3, y: 6}
        }
        complete: {
          message: gameMsg.createdTower
          params: [3, 6]
        }
      }
      {
        id: 'Show player their gold'
        text: {
          title: "This is your gold, you use gold to build towers and minions."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "gold"
            buttonSubType: "gold"
          }
        }
        complete: {
          time: 5
        }
      }
      {
        id: 'Show player their income'
        text: {
          title: "This is your income, you get this much gold every second."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "income"
            buttonSubType: "income"
          }
        }
        complete: {
          time: 7
        }
      }
      {
        id: 'Show player their souls'
        text: {
          title: "These are your souls, you use souls to create minions."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "souls"
            buttonSubType: "souls"
          }
        }
        complete: {
          time: 5
        }
      }
      {
        id: 'Land Drone Invading'
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "Oh no, invaders! Don't worry our tower will kill them."
        }
        action: {
          type: "spawnMinion"
          details: {
            minionType: "land-drone"
            spawnPointId: 0
          }
        }
        complete: {
          message: gameMsg.minionDied
        }
      }
      {
        id: 'Give gold for upgrade'
        action: {
          type: "giveGold"
          details: {
            amount: 60
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: 'Upgrade Tower'
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "Click on your tower to upgrade it."
        }
        highlight: {
          type: "position"
          details: {x: 3, y: 6}
        }
        complete: {
          message: gameMsg.entityClicked
        }
      }
      {
        id: 'Click Upgrade Button'
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "Click upgrade button"
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "upgradeButton"
            buttonSubType: "upgradeButton"
          }
        }
        complete: {
          message: gameMsg.upgradedTower
        }
      }
      {
        id: 'Upgrade Droids Invading'
        text: {
          title: "More droids are invading, good thing you upgraded."
        }
        action: {
          type: "spawnMinion"
          details: {
            minionType: "land-drone"
            spawnPointId: 0
          }
        }
        complete: {
          time: 1
        }
      }
      {
        id: 'Second Upgrade Droids Invading'
        action: {
          type: "spawnMinion"
          details: {
            minionType: "land-drone"
            spawnPointId: 0
          }
        }
        complete: {
          message: gameMsg.minionDied
        }
      }
      {
        complete: {
          message: gameMsg.minionDied
        }
      }
      {
        id: 'Give gold for knight'
        action: {
          type: "giveGold"
          details: {
            amount: 75
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: 'Select Knight'
        text: {
          title: "Click on your knight on the right to select it"
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "minion"
            buttonSubType: "knight"
          }
        }
        complete: {
          message: gameMsg.pickedMinion
          params: ['knight']
        }
      }
      {
        id: 'Send Knight'
        text: {
          title: "Click on your spawn point to place the knight"
        }
        highlight: {
          type: "position"
          details: {x: 20, y: 0}
        }
        complete: {
          message: gameMsg.createdMinion
        }
        reverse: {
          message: gameMsg.pickedMinion
          params: [false]
        }
      }
      {
        id: 'Send Minion Timeout'
        text: {
          title: "Wait for him to attack their base."
        }
        action: {
          type: 'unpickMinion'
        }
        complete: {
          time: 3
        }
      }
      {
        id: 'Opponent Building Tower'
        action: {
          type: "buildTower"
          details: {
            x: 20
            y: 6
            towerType: "turret"
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: 'Opponent Building 2nd Tower'
        action: {
          type: "buildTower"
          details: {
            x: 20
            y: 7
            towerType: "turret"
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: 'Opponent Building 3rd Tower'
        action: {
          type: "buildTower"
          details: {
            x: 21
            y: 4
            towerType: "flamer"
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: 'Opponent Building 4th Tower'
        action: {
          type: "buildTower"
          details: {
            x: 21
            y: 3
            towerType: "laser-beam"
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: "Opponent Smart"
        complete: {
          message: gameMsg.minionDied
        }
      }
      {
        id: "Collect Soul"
        text: {
          title: "Click the knights soul to collect it"
        }
        complete: {
          message: gameMsg.collectedGem
        }
      }
      {
        id: "Collected Soul"
        text: {
          xPos: 'center'
          yPos: 'bottom'
          title: "Souls restock your minions so you can send more"
          buttonText: "OK"
        }
        complete: {
          time: 5
        }
      }
      {
        id: 'Give gold for blacksmith'
        action: {
          type: "giveGold"
          details: {
            amount: 110
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: "Send Blacksmith"
        text: {
          title: "Send the blacksmith, he will make it past their defenses."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "minion"
            buttonSubType: "blacksmith"
          }
        }
        complete: {
          message: gameMsg.createdMinion
        }
      }
      {
        id: "Minions Give Income"
        text: {
          xPos: 'center'
          yPos: 'bottom'
          title: "Sending minions also increases your income."
        }
        action: {
          type: 'unpickMinion'
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "income"
            buttonSubType: "income"
          }
        }
        complete: {
          message: gameMsg.minionDied
        }
      }
      {
        id: "Sieging Castle"
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "We damaged their castle, destroy all their castles to win."
          buttonText: "OK"
        }
        complete: {
          time: 5
        }
      }
      {
        id: 'Give gold for 3 knights'
        action: {
          type: "giveGold"
          details: {
            amount: 225
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: "Send 3 Knights"
        text: {
          title: "Send groups of minions to get further, send 3 knights now"
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "minion"
            buttonSubType: "knight"
          }
        }
        complete: {
          message: gameMsg.createdMinion
        }
      }
      {
        id: "Send 3 Knights, part 2"
        text: {
          title: "Send groups of minions to get further, send 2 more knights"
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "minion"
            buttonSubType: "knight"
          }
        }
        complete: {
          message: gameMsg.createdMinion
        }
      }
      {
        id: "Send 3 Knights, part 3"
        text: {
          title: "Send groups of minions to get further, send 1 more knight"
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "minion"
            buttonSubType: "knight"
          }
        }
        complete: {
          message: gameMsg.createdMinion
        }
      }
      {
        id: "Income much higher"
        text: {
          xPos: 'center'
          yPos: 'bottom'
          title: "Wow look how high your income is now."
        }
        action: {
          type: 'unpickMinion'
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "income"
            buttonSubType: "income"
          }
        }
        complete: {
          time: 3
        }
      }
      {
        id: "Income much higher 2"
        text: {
          xPos: 'center'
          yPos: 'bottom'
          title: "Send minions throughout the game to grow your income."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "income"
            buttonSubType: "income"
          }
        }
        complete: {
          time: 3
        }
      }
      {
        id: 'Unpick knight'
        action: {
          type: 'unpickMinion'
        }
        complete: {
          time: 0
        }
      }
      {
        id: 'Give gold for cannon tower'
        action: {
          type: "giveGold"
          details: {
            amount: 80
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: "Opponent Attacking Again"
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "Build a cannon tower, it is much stronger than the crossbow."
        }
        action: {
          type: "spawnTempMinion"
          details: {
            minionType: "sky-drone"
            spawnPointId: 0
          }
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "tower"
            buttonSubType: "cannon"
          }
        }
        complete: {
          message: gameMsg.pickedTower
          params: ["cannon"]
        }
      }
      {
        id: "Placing Cannon Tower"
        highlight: {
          type: "position"
          details: {x: 2, y: 4}
        }
        complete: {
          message: gameMsg.clickPlaceTower
          params: [2, 4]
        }
        reverse: {
          message: gameMsg.pickedTower
          params: [false]
        }
      }
      {
        id: "Created Cannon Tower"
        highlight: {
          type: "position"
          details: {x: 2, y: 4}
        }
        complete: {
          message: gameMsg.createdTower
          params: [2, 4]
        }
      }
      {
        id: 'Give gold for spikes tower'
        action: {
          type: "giveGold"
          details: {
            amount: 70
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: "Build spikes tower"
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "Lets also build some spikes, they damage all minions in an area."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "tower"
            buttonSubType: "spikes"
          }
        }
        complete: {
          message: gameMsg.pickedTower
          params: ["spikes"]
        }
      }
      {
        id: "Placing Spikes"
        text: {
          title: "Spikes can only be built on roads."
        }
        highlight: {
          type: "position"
          details: {x: 3, y: 5}
        }
        complete: {
          message: gameMsg.clickPlaceTower
          params: [3, 5]
        }
        reverse: {
          message: gameMsg.pickedTower
          params: [false]
        }
      }
      {
        id: "Created Spikes"
        highlight: {
          type: "position"
          details: {x: 3, y: 5}
        }
        complete: {
          message: gameMsg.createdTower
          params: [3, 5]
        }
      }
      {
        id: "Spawned SkyDrone Attacker"
        text: false
        action: {
          type: "spawnMinion"
          details: {
            minionType: "sky-drone"
            spawnPointId: 0
          }
        }
        complete: {
          time: 1
        }
      }
      {
        id: "It's a flying unit"
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "Our opponent sent a flying unit, cannons and spikes can't attack them."
        }
        complete: {
          time: 3
        }
      }
      {
        id: "Build crossbow"
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "Quickly build another crossbow to shoot it down."
        }
        highlight: {
          type: "button"
          details: {
            buttonType: "tower"
            buttonSubType: "crossbow"
          }
        }
        complete: {
          message: gameMsg.pickedTower
          params: ["crossbow"]
        }
      }
      {
        id: "Placing 2nd Crossbow"
        highlight: {
          type: "position"
          details: {x: 3, y: 7}
        }
        complete: {
          message: gameMsg.clickPlaceTower
          params: [3, 7]
        }
        reverse: {
          message: gameMsg.pickedTower
          params: [false]
        }
      }
      {
        id: "Created 2nd Crossbow"
        highlight: {
          type: "position"
          details: {x: 3, y: 7}
        }
        complete: {
          message: gameMsg.createdTower
          params: [3, 7]
        }
      }
      {
        id: "Waiting on skydrone to die"
        complete: {
          message: gameMsg.minionDied
        }
      }
      {
        id: "Tutorial Finished"
        text: {
          xPos: 'center'
          yPos: 'center'
          title: "You now know the basics, see if you can beat the opponent."
        }
        complete: {
          time: 5
        }
      }
      {
        id: 'Give gold for finish'
        action: {
          type: "giveGold"
          details: {
            amount: 300
          }
        }
        complete: {
          time: 0
        }
      }
      {
        id: "Tutorial Finished"
        text: false
        finished: true
      }
    ]

  update: ->
    if ts.input? && ts.input.pressed("nextTutorialStep") && @inputPressed == false
      @inputPressed = true
      @nextStep()
    if ts.input? && !ts.input.pressed("nextTutorialStep")
      @inputPressed = false
    if @freePlayStarted
      @updateAI()

  nextStep: ->
    @endStep(@currentStep)
    @currentStep++
    @startStep(@currentStep)

  previousStep: ->
    stepInfo = @steps[@currentStep]
    ts.game.dispatcher.emit gameMsg.previousTutorialStep, stepInfo.id
    @endStep(@currentStep)
    @currentStep--
    @startStep(@currentStep)


  startStep: (stepNum) ->
    if !@steps[stepNum]?
      return false
    stepInfo = @steps[stepNum]
    ts.game.dispatcher.emit gameMsg.startTutorialStep, stepInfo.id
    if stepInfo.text?
      @showHelperText(stepInfo.text.title)
    if stepInfo.highlight?
      @highlight(stepInfo.highlight)
    if stepInfo.complete?
      @addComplete(stepInfo.complete)
    if stepInfo.reverse?
      @addReverse(stepInfo.reverse)
    if stepInfo.action?
      @doAction(stepInfo.action)
    if stepInfo.finished?
      @finishTutorial()

  endStep: (stepNum) ->
    if !@steps[stepNum]?
      return false
    stepInfo = @steps[stepNum]
    ts.game.dispatcher.emit gameMsg.endTutorialStep, stepInfo.id
    if stepInfo.text?
      @hideText(stepInfo.text)
    if stepInfo.highlight?
      @unHighlight(stepInfo.highlight)
    if stepInfo.complete?
      @removeComplete(stepInfo.complete)
    if stepInfo.reverse?
      @removeReverse(stepInfo.reverse)

  finishTutorial: ->
    #Set mode to pvp so we can build all towers / minions
    ts.game.dispatcher.emit gameMsg.finishTutorial
    ts.game.settings.mode = config.modes.pvp
    @startRandomAI()

  startRandomAI: ->
    @freePlayStarted = true


  updateAI: ->
    if !@freePlayStarted
      return false
    if @lastTick == ts.getCurrentTick()
      return false
    @lastTick = ts.getCurrentTick()
    chanceToSendMinion = 0.03
    chanceToBuildTower = 0.02
    if Math.random() < chanceToSendMinion
      possibleMinionTypes = ['landDrone', 'skyDrone']
      minionTypeNum = Math.floor(Math.random()*2)
      @doAction({type: "spawnMinion", details: { minionType: possibleMinionTypes[minionTypeNum], spawnPointId: 0}})
    if Math.random() < chanceToBuildTower
      possibleTowerTypes = ['turret', 'flamer', 'laserBeam', 'superLaser']
      towerTypeNum = Math.floor(Math.random()*4)
      x = Math.floor(Math.random()*12) + 13
      y = Math.floor(Math.random()*20)
      @doAction({type: "buildTower", details: {towerType: possibleTowerTypes[towerTypeNum], x, y}})



  showText: (settings)  ->
    if settings == false
      ts.game.hud.hideInfoPanel()
    else
      xPos = 'center'
      yPos = 'bottom'
      title = ''
      text = ''
      buttonText = null
      if typeof settings == "string"
        text = settings
      else
        if settings.xPos? then xPos = settings.xPos
        if settings.yPos? then yPos = settings.yPos
        if settings.title? then title = settings.title
        if settings.text? then text = settings.text
        if settings.buttonText? then buttonText = settings.buttonText
      ts.game.hud.showInfoPanel(xPos, yPos, title, text, buttonText)

  hideText: (text) ->
    ts.game.hud.removeMessage(text)

  showHelperText: (text) ->
    ts.game.hud.showHelperText(text)

  hideHelperText: ->
    ts.game.hud.hideHelperText()

  doAction: (settings) ->
    details = settings.details
    if settings.type == "spawnMinion"
      spawnPoint = ts.game.map.spawnPoints[details.spawnPointId]
      minionDetails = ts.getConfig('minions', details.minionType)
      minionDetails.nodePath = details.spawnPointId
      minionDetails.team = 1
      ts.game.minionManager.spawnMinion(spawnPoint.x, spawnPoint.y, minionDetails)
    else if settings.type == "spawnTempMinion"
      ts.game.dispatcher.emit gameMsg.getPlayer, @opponentId, (opponent) =>
        ts.game.minionManager.spawnTempMinion(details.minionType, opponent)
    else if settings.type == "buildTower"
      ts.game.dispatcher.emit gameMsg.getPlayer, @opponentId, (opponent) =>
        ts.game.towerManager.spawnTower(settings.details.x, settings.details.y, settings.details.towerType, @opponentId);
    else if settings.type == "createPlayer"
      ts.game.dispatcher.emit gameMsg.createPlayer, @opponentId, (opponent) =>
        opponent.team = 1
        opponent.race = "elementals"
    else if settings.type == "giveGold"
      ts.game.playerManager.player.addGold(details.amount)
    else if settings.type == "unpickMinion"
      ts.game.dispatcher.emit gameMsg.unpickMinion


  highlight: (settings) ->
    switch settings.type
      when 'button'
        @highlightButton(settings.details)
      when 'position'
        @highlightPosition(settings.details)
      when 'area'
        @highlightArea(settings.details)

  highlightButton: (settings) ->
    ts.game.dispatcher.emit gameMsg.highlightButton, settings.buttonType, settings.buttonSubType

  highlightPosition: (settings) ->
    ts.game.dispatcher.emit gameMsg.highlightPosition, settings

  highlightArea: (settings) ->
    ts.game.dispatcher.emit gameMsg.highlightArea, settings

  unHighlight: (settings) ->
    switch settings.type
      when 'button'
        details = _.clone(settings.details)
        details.buttonSubType = null
        @highlightButton(details)
      when 'position'
        @highlightPosition(null)

  addComplete: (settings) ->
    if settings.time?
      @completeTimeout = setTimeout =>
          @nextStep()
        ,settings.time * 1000
    if settings.message?
      @completeListener = ts.game.dispatcher.on settings.message, () =>
        if settings.params?
          for item, idx in settings.params
            if arguments[idx] != item
              return false
        @nextStep();

  removeComplete: () ->
    if !@completeListener?
      return false
    ts.game.dispatcher.off @completeListener
    @completeListener = null

  addReverse: (settings) ->
    if settings.message?
      @reverseListener = ts.game.dispatcher.on settings.message, () =>
        if settings.params?
          for item, idx in settings.params
            if arguments[idx] != item
              return false
        @previousStep();

  removeReverse: () ->
    if !@reverseListener?
      return false
    ts.game.dispatcher.off @reverseListener
    @reverseListener = null

module.exports = TutorialManager
