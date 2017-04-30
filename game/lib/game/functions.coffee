
functions = {
  getDist: (pos, target) ->
    xDist = target.x - pos.x;
    yDist = target.y - pos.y;
    dist = Math.sqrt(xDist*xDist + yDist*yDist);
    return dist;

  getDistSqrd: (pos, target) ->
    xDist = target.x - pos.x;
    yDist = target.y - pos.y;
    distSqrd = xDist * xDist + yDist * yDist
    return distSqrd

  pointInsideBox: (point, box) ->
    if point.x < box.x || point.x > (box.x + box.w) || point.y < box.y || point.y > (box.y + box.h)
      return false
    return true

  calcVel: (pos, target, speed) ->
    xDist = target.x - pos.x;
    yDist = target.y - pos.y;
    dist = Math.sqrt(xDist*xDist + yDist*yDist);
    unitVec = {x: xDist / dist, y: yDist / dist};
    vel = {x: unitVec.x * speed, y: unitVec.y * speed};
    return vel;

  calcAngle: (vec1, vec2) ->
    yDist = vec2.y - vec1.y
    xDist = vec2.x - vec1.x
    angle = Math.atan2(yDist, xDist)
    return angle;

  calcAngleInRadians: (vec1, vec2) ->
    return @calcAngle(vec1, vec2);

  calcAngleInDegrees: (vec1, vec2) ->
    return @calcAngle(vec1, vec2) * 180 / Math.PI

  getDirectionVector: (angleInDegrees, magnitude = 1) ->
    angleInRad = angleInDegrees / 180 * Math.PI
    xDist = (Math.cos(angleInRad) * magnitude).round(8)
    yDist = (Math.sin(angleInRad) * magnitude).round(8)
    return {x: xDist, y: yDist}

  add: (vec1, vec2) ->
    returnVec = {x: vec1.x + vec2.x, y: vec1.y + vec2.y}

}

module.exports = functions;