((exports) ->
  config =
    roles: ["public", "user", "admin"]
    accessLevels:
      public: "*"
      anon: ["public"]
      user: ["user", "admin"]
      admin: ["admin"]

  buildRoles = (roles) ->
    bitMask = "01"
    userRoles = {}
    for role of roles
      intCode = parseInt(bitMask, 2)
      userRoles[roles[role]] =
        bitMask: intCode
        title: roles[role]
      bitMask = (intCode << 1).toString(2)
    userRoles

  buildAccessLevels = (accessLevelDeclarations, userRoles) ->
    accessLevels = {}
    for level of accessLevelDeclarations
      if typeof accessLevelDeclarations[level] is "string"
        if accessLevelDeclarations[level] is "*"
          resultBitMask = ""
          for role of userRoles
            resultBitMask += "1"
          accessLevels[level] =
            bitMask: parseInt(resultBitMask, 2)
            title: accessLevelDeclarations[level]
        else
          console.log "Access Control Error: Could not parse '" + accessLevelDeclarations[level] + "' as access definition for level '" + level + "'"
      else
        resultBitMask = 0
        for role of accessLevelDeclarations[level]
          if userRoles.hasOwnProperty(accessLevelDeclarations[level][role])
            resultBitMask = resultBitMask | userRoles[accessLevelDeclarations[level][role]].bitMask
          else
            console.log "Access Control Error: Could not find role '" + accessLevelDeclarations[level][role] + "' in registered roles while building access for '" + level + "'"
        accessLevels[level] =
          bitMask: resultBitMask
          title: accessLevelDeclarations[level][role]
    accessLevels

  exports.userRoles = buildRoles(config.roles)
  exports.accessLevels = buildAccessLevels(config.accessLevels, exports.userRoles)
) (if typeof exports is "undefined" then this["authConfig"] = {} else exports)
