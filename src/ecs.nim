import 
  random,
  algorithm,
  tables,
  typetraits,
  macros

type
  Rect* = ref object 
    x, y, w, h: int

  Component* = ref object of RootObj

  Entity* = ref EntityObj
  EntityObj* = object
    id*: string
    x*, y*: int
    w*, h*: int
    z*: int
    components: Table[string, Component]

  EntityManager* = ref EntityManagerObj
  EntityManagerObj* = object
    entities*: seq[Entity]
    
proc typename*[T](sym: T): string = 
  sym.type.name

proc type_to_string*(t: typedesc): string = 
  t.name

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Entity
proc newEntity*(x, y, w, h: int, z: int = 0, name: string = nil): Entity = 
  new result
  result.components = initTable[string, Component]()
  result.x = x
  result.y = y
  result.w = w
  result.h = h
  result.z = z

  if name == nil:
    result.id = "entity" & $random(0.high)
  else:
    result.id = name

proc add*[T: Component](this: Entity, component: T): Entity =
  result = this
  result.components[component.typename] = component

proc remove*(this: Entity, comp_type: typedesc) =
  let name = comp_type.name
  if this.components.contains(name):
    this.components.del(name)

proc get*[T: Component](this: Entity, component_type: typedesc[T]): T = 
  T(this.components[component_type.name])

proc has*(this: Entity, types: varargs[string, `type_to_string`]): bool =
  for t in types:
    if not this.components.contains t: return false
  true

# proc move(e: var Entity, xVel, yVel, dt: float) = 
#   e.x += xVel * dt
#   e.y += yVel * dt

# proc moveLeft(e: var Entity, dt: float) =
#   e.move(-e.velocity, 0, dt)

# proc moveRight(e: var Entity, dt: float) = 
#   e.move(e.velocity, 0, dt)

# proc moveUp(e: var Entity, dt: float) = 
#   e.move(0, -e.velocity, dt)

# proc moveDown(e: var Entity, dt: float) = 
#   e.move(0, e.velocity, dt)



#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> EntityManager
proc newEntityManager*(): EntityManager = 
  new result
  result.entities = @[]

proc add*(em: var EntityManager, e: Entity) =
  em.entities.add(e)
  em.entities = em.entities.sortedByIt it.z

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Components

#=> Base methods
# method update(this: PhysicsComponent, e: var Entity, 
#     game: Game, dt: float) {.base.} = 
#   discard
# method render(this: GraphicsComponent, e: Entity, 
#     game: Game, lag: float) {.base.} = 
#   discard

# #=> PlayerPhysicsComponent
# proc newPlayerPhysicsComponent(): PlayerPhysicsComponent =
#   new result

# method update(this: PlayerPhysicsComponent, e: var Entity, 
#     game: Game, dt: float) =

#   if game.isCommand(Command.SpeedUp):
#     e.velocity = 800
#   else:
#     e.velocity = 100

#   if game.isCommand(Command.Left):
#     e.moveLeft(dt)
#   elif game.isCommand(Command.Right):
#     e.moveRight(dt)
#   if game.isCommand(Command.Up):
#     e.moveUp(dt)
#   elif game.isCommand(Command.Down):
#     e.moveDown(dt)
  
#   game.camera.x = e.x.int
#   game.camera.y = e.y.int

# #=> PlayerGraphicsComponent
# proc newPlayerGraphicsComponent(ren: RendererPtr): PlayerGraphicsComponent =
#   new result 
#   result.renderer = ren
#   result.color = (random(255).uint8, random(255).uint8, random(255).uint8)

# method render(this: PlayerGraphicsComponent, e: Entity, 
#     game: Game, lag: float) = 
#   let (screenX, screenY) = game.camera.getScreenLocation((e.x, e.y))

#   var toDraw = rect(screenX, screenY, e.w.cint, e.h.cint)
#   var r, g, b, a: uint8
#   this.renderer.getDrawColor(r, g, b, a)
#   this.renderer.setDrawColor(this.color.r, this.color.g, this.color.b)

#   this.renderer.fillRect(toDraw)

#   this.renderer.setDrawColor(r, g, b, a)

# #=> AIPhysicsComponent
# proc newAIPhysicsComponent(): AIPhysicsComponent =
#   new result

# method update(this: AIPhysicsComponent, e: var Entity, 
#     game: Game, dt: float) =
#   discard

# #=> BoundingBoxPhysicsComponent
# proc newBoundingBoxPhysicsComponent(): BoundingBoxPhysicsComponent =
#   new result

# method update(this: BoundingBoxPhysicsComponent, e: var Entity, 
#     game: Game, dt: float) =
#   let this_bounds = (
#     right: (e.x.int + e.w).cint,
#     left: e.x.cint,
#     top: e.y.cint,
#     bottom: (e.y + e.h.float).cint
#   )

#   for entity in game.em.entities.mitems:
#     let entity_bounds = (
#       right: (entity.x.int + entity.w).cint,
#       left: entity.x.cint,
#       top: entity.y.cint,
#       bottom: (entity.y + entity.h.float).cint
#     )
    
#     if entity_bounds.left <= this_bounds.left: 
#       entity.x = e.x 
#     elif entity_bounds.right >= this_bounds.right:
#       entity.x = e.x + (this_bounds.right - entity.w).float
    
#     if entity_bounds.top <= this_bounds.top:
#       entity.y = e.y
#     elif entity_bounds.bottom >= this_bounds.bottom:
#       entity.y = e.y + (this_bounds.bottom - entity.h).float

# #=> TextureGraphicsComponent
# proc newTextureGraphicsComponent(ren: RendererPtr, 
#     texture: TexturePtr, dest: Rect): TextureGraphicsComponent =
#   new result 
#   result.renderer = ren
#   result.texture = texture
#   result.destRect = dest

# method render(this: TextureGraphicsComponent, e: Entity, 
#     game: Game, lag: float) = 
#   let (screenX, screenY) = 
#     game.camera.getScreenLocation((this.destRect.x, this.destRect.y))
#   let dest = rect(screenX, screenY, this.destRect.w, this.destRect.h)
#   this.renderer.copy(this.texture, nil, unsafeaddr dest)
  