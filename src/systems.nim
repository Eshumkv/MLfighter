import 
  ecs, 
  game,
  components, 
  sdl2,
  macros

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Render System
proc render*[T](game: T, lag: float) = 
  for entity in game.em.entities:
    # TODO: Check if entity has all the necessary components!
    if not entity.has(AABB, ColorComponent): 
      return 

    let 
      aabb = entity.get(AABB)
      color = entity.get(ColorComponent)
    
    let (screenX, screenY) = game.camera.getScreenLocation((aabb.x, aabb.y))

    var toDraw = rect(screenX, screenY, aabb.w.cint, aabb.h.cint)
    var r, g, b, a: uint8
    game.renderer.getDrawColor(r, g, b, a)
    game.renderer.setDrawColor(color.r, color.g, color.b)

    game.renderer.fillRect(toDraw)

    game.renderer.setDrawColor(r, g, b, a)

  
# method render(this: PlayerGraphicsComponent, e: Entity, 
#     game: Game, lag: float) = 
#   let (screenX, screenY) = game.camera.getScreenLocation((e.x, e.y))

#   var toDraw = rect(screenX, screenY, e.w.cint, e.h.cint)
#   var r, g, b, a: uint8
#   this.renderer.getDrawColor(r, g, b, a)
#   this.renderer.setDrawColor(this.color.r, this.color.g, this.color.b)

#   this.renderer.fillRect(toDraw)

#   this.renderer.setDrawColor(r, g, b, a)