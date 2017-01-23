import 
  times,
  os,
  sdl2,
  sdl2.image,
  sequtils,
  math,
  random

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Enums
type
  Command {.pure.} = enum 
    None,
    Fullscreen,
    Shoot,
    Left,
    Up, 
    Right, 
    Down
    
  FullscreenType* {.pure.} = enum
    Windowed,
    Fullscreen,
    Desktop

#=> Components
type
  Color = tuple 
    r: uint8
    g: uint8
    b: uint8

  PhysicsComponent = ref object of RootObj
  GraphicsComponent = ref object of RootObj

  PlayerPhysicsComponent = ref object of PhysicsComponent  
  PlayerGraphicsComponent = ref object of GraphicsComponent
    renderer: RendererPtr
    color: Color
  
  AIPhysicsComponent = ref object of PhysicsComponent

type
  Entity = ref EntityObj
  EntityObj = object
    velocity: float
    x, y: float
    w, h: int
    physics: PhysicsComponent
    graphics: PlayerGraphicsComponent
    name: string

type 
  Game* = ref GameObj
  GameObj = object 
    renderer: RendererPtr
    background: TexturePtr
    dt: float
    em: EntityManager
    player: Entity
    camera: Camera2D
    commands: array[Command, (bool, bool)] # (pressed, repeat)
    setFullscreen*: (proc (isFullscreen: bool, ftype: FullscreenType): void)
    isFullscreen: bool
    quitCallback*: (proc (): void)
    
  Camera2D = ref CameraObj
  CameraObj = object 
    x: int
    y: int
    halfWidth: int
    halfHeight: int

  EntityManager = ref EntityManagerObj
  EntityManagerObj = object
    entities: seq[Entity]
    game: Game

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc isCommandPressed(game: Game, command: Command): bool = 
  let (pressed, repeat) = game.commands[command]
  return pressed and not repeat

proc isCommand(game: Game, command: Command): bool = 
  let (pressed, _) = game.commands[command]
  return pressed

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newCamera(w, h: int): Camera2D = 
  new result
  result.halfWidth = w div 2
  result.halfHeight = h div 2

proc getScreenLocation(camera: Camera2D, location: (float, float)): (cint, cint) = 
  var 
    screenX = (location[0].int - camera.x) + camera.halfWidth
    screenY = (location[1].int - camera.y) + camera.halfHeight
  
  result = (screenX.cint, screenY.cint)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Entity
proc newEntity*(p: PhysicsComponent, g: PlayerGraphicsComponent, name: string = nil): Entity = 
  new result
  result.physics = p
  result.graphics = g
  result.velocity = 100

  if name == nil:
    result.name = "entity" & $random(int.high)
  else:
    result.name = name

proc move(e: var Entity, xVel, yVel, dt: float) = 
  e.x += xVel * dt
  e.y += yVel * dt

proc moveLeft(e: var Entity, dt: float) =
  e.move(-e.velocity, 0, dt)

proc moveRight(e: var Entity, dt: float) = 
  e.move(e.velocity, 0, dt)

proc moveUp(e: var Entity, dt: float) = 
  e.move(0, -e.velocity, dt)

proc moveDown(e: var Entity, dt: float) = 
  e.move(0, e.velocity, dt)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Components

#=> Base methods
method update(this: PhysicsComponent, e: var Entity, 
    game: Game, dt: float) {.base.} = 
  discard
method render(this: GraphicsComponent, e: Entity, 
    game: Game, lag: float) {.base.} = 
  discard

#=> PlayerPhysicsComponent
proc newPlayerPhysicsComponent(): PlayerPhysicsComponent =
  new result

method update(this: PlayerPhysicsComponent, e: var Entity, 
    game: Game, dt: float) =
  if game.isCommand(Command.Left):
    e.moveLeft(dt)
  elif game.isCommand(Command.Right):
    e.moveRight(dt)
  if game.isCommand(Command.Up):
    e.moveUp(dt)
  elif game.isCommand(Command.Down):
    e.moveDown(dt)
  
  game.camera.x = e.x.int
  game.camera.y = e.y.int

#=> PlayerGraphicsComponent
proc newPlayerGraphicsComponent(ren: RendererPtr, color: Color = (255.uint8, 0.uint8, 0.uint8)): PlayerGraphicsComponent =
  new result 
  result.renderer = ren
  result.color = color

method render(this: PlayerGraphicsComponent, e: Entity, 
    game: Game, lag: float) = 
  var (screenX, screenY) = game.camera.getScreenLocation((e.x, e.y))

  var toDraw = rect(screenX, screenY, 50, 50)
  var r, g, b, a: uint8
  this.renderer.getDrawColor(r, g, b, a)
  this.renderer.setDrawColor(this.color.r, this.color.g, this.color.b)

  this.renderer.fillRect(toDraw)

  this.renderer.setDrawColor(r, g, b, a)

#=> AIPhysicsComponent
proc newAIPhysicsComponent(): AIPhysicsComponent =
  new result

method update(this: AIPhysicsComponent, e: var Entity, 
    game: Game, dt: float) =
  discard
  
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> EntityManager
proc newEntityManager(g: Game): EntityManager = 
  new result
  result.entities = @[]
  result.game = g

proc add(em: var EntityManager, e: Entity) =
  em.entities.add(e)

proc render(em: EntityManager, game: Game, lag: float) =
  for e in em.entities: 
    e.graphics.render(e, game, lag)

proc update(em: var EntityManager, dt: float) =
  for e in em.entities.mitems: 
    e.physics.update(e, em.game, dt)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc render*(game: Game, lag: float) = 
  ## This causes the game to render itself to the specified renderer
  game.renderer.clear()

  #game.renderer.copy(game.background, nil, nil)

  game.em.render(game, lag)

  game.renderer.present()

proc toCommand(key: cint): Command = 
  case key:
  of K_F11:
    result = Command.Fullscreen
  of K_W:
    result = Command.Up
  of K_S:
    result = Command.Down
  of K_A:
    result = Command.Left
  of K_D:
    result = Command.Right
  of K_Space:
    result = Command.Shoot
  else:
    result = Command.None

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc processSystemCommand(game: Game, command: Command) = 
  case command:
  of Command.Fullscreen:
    game.isFullscreen = not game.isFullscreen

    if game.setFullscreen != nil:
      if game.isFullscreen:
        game.setFullscreen(game.isFullscreen, FullscreenType.Desktop)
      else:
        game.setFullscreen(game.isFullscreen, FullscreenType.Windowed)
  else:
    discard

proc processInput*(game: var Game) = 
  var event = defaultEvent 

  while pollEvent(event):
    case event.kind:
    of QuitEvent:
      if game.quitCallback != nil:
        game.quitCallback()
      else:
        # TODO: log it? 
        echo "Trying to quit :("
    of KeyDown:
      let command = event.key.keysym.sym.toCommand
      game.commands[command] = (true, event.key.repeat)
      if not event.key.repeat:
        game.processSystemCommand(command)
    of KeyUp:
      game.commands[event.key.keysym.sym.toCommand] = (false, false)
    else:
      discard

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc update*(game: var Game, elapsed: float) = 
  game.dt = elapsed

  game.em.update(game.dt)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc quit*(game: Game) = 
  game.background.destroy()
  game.renderer.destroy()

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newGame*(ren: RendererPtr, size: (cint, cint)): Game = 
  new result 
  result.renderer = ren
  result.background = ren.loadTexture(getAppDir() / "res/img/bg.jpg")
  result.em = newEntityManager(result)
  result.camera = newCamera(size[0], size[1])

  randomize(epochTime().int)
  
  discard result.renderer.setDrawColor(110, 132, 174)

  result.player = newEntity(
    newPlayerPhysicsComponent(), 
    newPlayerGraphicsComponent(result.renderer),
    "player"
  )
  result.player.w = 50
  result.player.h = 50
  result.em.add(result.player)
  
  #Test
  var test = newEntity(
    newAIPhysicsComponent(),
    newPlayerGraphicsComponent(result.renderer, (255.uint8, 255.uint8, 0.uint8))
  )
  test.x = 200
  test.y = 200
  result.em.add(test)
