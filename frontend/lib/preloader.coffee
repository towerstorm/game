
### Assets are loaded in this order ###
assetGroups = {
  lobby: 'lobby'
  gameLobby: 'gameLobby'
  gameUI: 'gameUI'
  gameAssets: 'gameAssets'
  gameOther: "gameOther"
  towers: "towers"
  minions: "minions"
  bullets: "bullets"
  vfx: "vfx"
  maps: "maps"
  gameSummary: "gameSummary"
  mobile: "mobile"
  unused: "unused"
}

assets = {
  'castles/crusaders-blue.png': assetGroups.gameAssets
  'castles/crusaders-blue-final.png': assetGroups.gameAssets
  'castles/crusaders-red.png': assetGroups.gameAssets
  'castles/crusaders-red-final.png': assetGroups.gameAssets
  'castles/shadow-blue.png': assetGroups.gameAssets
  'castles/shadow-blue-final.png': assetGroups.gameAssets
  'castles/shadow-red.png': assetGroups.gameAssets
  'rubble.png': assetGroups.gameAssets
  'shadow.png': assetGroups.gameAssets
  'soul-white.png': assetGroups.gameAssets
  'spawn-point-blue.png': assetGroups.gameAssets
  'spawn-point-red.png': assetGroups.gameAssets
}


preloader =
  started: false
  pxFinished: false
  pixiFinished: false
  pxProgressListener: null
  pixiProgressListener: null
  pixiLoadedTotal: 0
  completeListeners: []

  start: () ->
    if @started
      return false

    @addRaces()
    @addMinions()
    @addTowers()
    @addBullets()
    @addVFX()
    @addMaps()

    loader = new PxLoader()
    pixiAssets = []
    totalPixiAssets = 0

    #Put the assets into an with all other assets in it's group, then we load the groups one at a time.
    assetsToBeLoaded = {}
    for own name, group of assets
      assetsToBeLoaded[group] = assetsToBeLoaded[group] || []
      assetsToBeLoaded[group].push(name)
    for own group, groupName of assetGroups
      assets = assetsToBeLoaded[group]
      if assets?
        for name in assets
          imagePath = '/img/' + name
          if groupName in ['gameAssets', 'towers', 'minions', 'bullets', 'vfx']
            pixiAssets.push(imagePath)
          else
            loader.add(new PxLoaderImage(imagePath, group))

    totalPixiAssets = pixiAssets.length;
    window.pixiAssets = pixiAssets;
    pixiLoader = new PIXI.AssetLoader(pixiAssets);

    loader.addCompletionListener () =>
      @pxFinished = true
      if @completeListeners?
        for completeListener in @completeListeners
          completeListener(true)
      return true

    loader.addProgressListener (e) =>
      if @pxProgressListener?
#        console.log("Loaded image: ", e.resource.getName())
        progressPercent = Math.round((e.completedCount / e.totalCount) * 100)
        @pxProgressListener(progressPercent) #Reports percent complete

    pixiLoader.onComplete = () =>
      @pixiFinished = true
      for completeListener in @completeListeners
        completeListener(true)

    pixiLoader.onProgress = (item) =>
      @pixiLoadedTotal++
      pixiAssets.erase(item)
      if @pixiProgressListener?
        progressPercent = Math.round((@pixiLoadedTotal / totalPixiAssets) * 100)
        @pixiProgressListener(progressPercent)

    loader.start();
    pixiLoader.load();
    @started = true;

  onPxProgress: (callback) ->
    @pxProgressListener = callback
    if @pxFinished
      callback(100)

  onPixiProgress: (callback) ->
    @pixiProgressListener = callback
    if @pixiFinished
      callback(100)

  onComplete: (callback) ->
    @completeListeners.push(() =>
      if @pxFinished && @pixiFinished
        callback(true)
    )
    if @pxFinished && @pixiFinished
      callback(true)
    return true

  addRaces: ->
    if window.config?.races?
      for own name, details of window.config.races
        assets['race-icons/' + name + ".png"] = assetGroups.gameLobby


  addMinions: ->
    if window.config?.minions?
      for own name, details of window.config.minions
        assets['minions/' + details.imageName] = assetGroups.minions
        assets['minion-icons/' + details.imageName] = assetGroups.gameUI

  addTowers: ->
    if window.config?.towers?
      for own name, details of window.config.towers
        assets['towers/' + details.imageName] = assetGroups.towers
        assets['tower-icons/' + details.imageName] = assetGroups.gameUI

  addBullets: ->
    if window.config?.bullets?
      for own name, details of window.config.bullets
        assets['bullets/' + details.imageName] = assetGroups.bullets

  addVFX: ->
    if window.config?.vfx?
      for own name, details of window.config.vfx
        assets['vfx/' + details.imageName] = assetGroups.vfx

  addMaps: ->
    if window.config?.maps?
      for own name, details of window.config.maps
        assets['maps/' + details.background] = assetGroups.maps

window.tsloader = preloader
