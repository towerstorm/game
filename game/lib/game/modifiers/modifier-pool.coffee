modifiers = {
  AoeModifier: require("./bullet/aoe.coffee"),
  BoxAoeModifier: require("./bullet/box-aoe.coffee"),
  FreezeModifier: require("./bullet/freeze.coffee"),
  PoisonModifier: require("./bullet/poison.coffee"),
  SlowModifier: require("./bullet/slow.coffee"),
  StunModifier: require("./bullet/stun.coffee"),
  TeleportModifier: require("./bullet/teleport.coffee"),
  CorpseExplosionModifier: require("./tower/corpse-explosion.coffee")
}


class ModifierPool
  mods: {}

  constructor: ->
    @reset();

  bindDispatcher: ->

  reset: ->
    @mods = {}

  setupMod: (mod, details) ->
    mod.reset.call(mod)
    mod.setup.apply(mod, details)
    return mod

  addModToPool: (mod) ->
    name = mod.name
    mod.reset();
    this.mods[name].push(mod);

  convertNameToClass: (name) ->
    name = name.replace(/-(\w)/g, (match, capture) -> capture.toUpperCase())
    firstCap = name.charAt(0).toUpperCase();
    upperCaseName = firstCap + name.substr(1)
    modifierName = upperCaseName + "Modifier"
    return modifierName

  getModifier: (name, details) ->
    arePropertiesReset = (item) ->
      for prop, value of item
        if (item.hasOwnProperty(prop))
          if (['visible', 'alpha'].indexOf(prop) == -1)
            if (typeof item[prop] == "object")
              arePropertiesReset(item[prop])
            else if (typeof item[prop] != "function")
              if (item[prop])
                throw new Error("Property " + prop + " has a value of: " + item[prop] + " after reset");
    @mods[name] = @mods[name] || []
    if @mods[name].length == 0
      mod = new modifiers[@convertNameToClass(name)]
    else
      mod = @mods[name].pop()
    mod = @setupMod(mod, details)
    return mod

module.exports = ModifierPool
