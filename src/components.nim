import ecs

type 
  AABB* = ref object of Component
    x*, y*: int
    w*, h*: int
  
  ColorComponent* = ref object of Component
    r*, g*, b*: uint8

  Dummy* = ref object of Component

proc newDummy*(): Dummy = new result

proc newAABB*(x, y, w, h: int): AABB =
  new result
  result.x = x
  result.y = y 
  result.w = w
  result.h = h

proc newColorComponent*(r, g, b: uint8): ColorComponent =
  new result
  result.r = r
  result.g = g
  result.b = b