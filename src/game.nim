import 
  os,
  sdl2,
  sdl2.image,
  sequtils

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
  PhysicsComponent = ref object of RootObj
  GraphicsComponent = ref object of RootObj

  PlayerPhysicsComponent = ref object of PhysicsComponent  
  PlayerGraphicsComponent = ref object of GraphicsComponent
    renderer: RendererPtr

type
  Entity = object
    velocity: float
    x, y: float
    w, h: int
    physics: PhysicsComponent
    graphics: PlayerGraphicsComponent

type 
  Game* = ref GameObj
  GameObj = object 
    renderer: RendererPtr
    background: TexturePtr
    dt: float
    em: EntityManager
    player: Entity
    commands: array[Command, (bool, bool)] # (pressed, repeat)
    setFullscreen*: (proc (isFullscreen: bool, ftype: FullscreenType): void)
    isFullscreen: bool
    quitCallback*: (proc (): void)

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

#=> Entity
proc newEntity*(p: PhysicsComponent, g: PlayerGraphicsComponent): Entity = 
  Entity(
    velocity: 0,
    x: 0,
    y: 0,
    physics: p,
    graphics: g
  )

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

#=> Base methods
method update(this: PhysicsComponent, e: var Entity, 
    game: Game, dt: float) {.base.} = 
  discard
method render(this: GraphicsComponent, e: Entity, lag: float) {.base.} = 
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

#=> PlayerGraphicsComponent
proc newPlayerGraphicsComponent(ren: RendererPtr): PlayerGraphicsComponent =
  new result 
  result.renderer = ren

method render(this: PlayerGraphicsComponent, e: Entity, lag: float) = 
  var toDraw = rect((cint)e.x, (cint)e.y, 50, 50)
  var r, g, b, a: uint8
  this.renderer.getDrawColor(r, g, b, a)
  this.renderer.setDrawColor(255, 0, 0)

  this.renderer.fillRect(toDraw)

  this.renderer.setDrawColor(r, g, b, a)
  
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> EntityManager
proc newEntityManager(g: Game): EntityManager = 
  new result
  result.entities = @[]
  result.game = g

proc add(em: var EntityManager, e: Entity) =
  em.entities.add(e)

proc render(em: EntityManager, lag: float) =
  for e in em.entities: 
    e.graphics.render(e, lag)

proc update(em: var EntityManager, dt: float) =
  for e in em.entities.mitems: 
    e.physics.update(e, em.game, dt)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc render*(game: Game, lag: float) = 
  ## This causes the game to render itself to the specified renderer
  game.renderer.clear()

  game.renderer.copy(game.background, nil, nil)

  game.em.render(lag)

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

proc newGame*(ren: RendererPtr): Game = 
  new result 
  result.renderer = ren
  result.background = ren.loadTexture(getAppDir() / "res/img/bg.jpg")
  result.em = newEntityManager(result)
  
  discard result.renderer.setDrawColor(110, 132, 174)

  result.player = newEntity(
    newPlayerPhysicsComponent(), 
    newPlayerGraphicsComponent(result.renderer)
  )
  result.player.velocity = 10
  result.player.w = 50
  result.player.h = 50
  result.em.add(result.player)
