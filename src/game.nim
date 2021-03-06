import 
  times,
  os,
  sdl2,
  sdl2.image,
  sequtils,
  math,
  random,
  ecs

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Enums
type
  Command* {.pure.} = enum 
    None,
    Fullscreen,
    Shoot,
    Left,
    Up, 
    Right, 
    Down,
    SpeedUp
    
  FullscreenType* {.pure.} = enum
    Windowed,
    Fullscreen,
    Desktop

type 
  #Game* = ref GameObj # In functional programming you never need it? 
  GameObj* = object 
    renderer*: RendererPtr
    em: EntityManager
    player: Entity # TODO: remove
    camera*: Camera2D
    commands: array[Command, bool]
    last_commands: array[Command, bool]
    setFullscreen: (proc (isFullscreen: bool, ftype: FullscreenType): void)
    isFullscreen: bool
    quitCallback: (proc (): void)
    next_scene: (proc (game: GameObj): GameObj)
    next_scene_clear_entities: bool
    mouse*: MouseState
    
  Camera2D* = ref CameraObj
  CameraObj* = object 
    x*: int
    y*: int
    halfWidth: int
    halfHeight: int
  
  MouseState* = object 
    left*: bool
    middle*: bool
    right*: bool
    x1*: bool
    x2*: bool
    x*, y*: int

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc is_command_pressed*(game: GameObj, command: Command): bool = 
  return game.commands[command] and not game.last_commands[command]

proc is_command*(game: GameObj, command: Command): bool = 
  return game.commands[command] 

proc is_any_key*(game: GameObj): bool =
  for pressed in game.commands:
    if pressed:
      return true

  let m = game.mouse
  if m.left or m.middle or m.right or m.x1 or m.x2:
    return true
  
  return false

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newCamera(w, h: int): Camera2D = 
  new result
  result.halfWidth = w div 2
  result.halfHeight = h div 2

proc get_screen_location*[T](
    camera: Camera2D, location: (T, T)): (cint, cint) = 
  var 
    screenX = (location[0].int - camera.x) + camera.halfWidth
    screenY = (location[1].int - camera.y) + camera.halfHeight
  
  result = (screenX.cint, screenY.cint)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc change_scene*(
    game: GameObj, clear_entities: bool, 
    scene: (proc (game: GameObj): GameObj)): GameObj =
  result = game
  result.next_scene = scene
  result.next_scene_clear_entities = clear_entities

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc add_entity*(game: GameObj, entity: Entity): GameObj =
  result = game
  result.em.add(entity)

proc remove_entity*(game: GameObj, entity: Entity): GameObj =
  result = game
  result.em.remove(entity)

proc all_entities*(game: GameObj): seq[Entity] =
  game.em.entities

iterator all_m_entities*(game: var GameObj): var Entity =
  var i = 0
  while i < len(game.em.entities):
    yield game.em.entities[i]
    inc(i)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

import 
  components
from systems import nil
from scenes import nil

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc render*(game: GameObj, lag: float) = 
  game.renderer.clear()
  systems.handle_rendering(game, lag)
  game.renderer.present()

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

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
  of K_LSHIFT:
    result = Command.SpeedUp
  else:
    result = Command.None

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc processSystemCommand(game: GameObj, command: Command): GameObj = 
  result = game
  case command:
  of Command.Fullscreen:
    result.isFullscreen = not game.isFullscreen

    if game.setFullscreen != nil:
      if game.isFullscreen:
        result.setFullscreen(result.isFullscreen, FullscreenType.Desktop)
      else:
        result.setFullscreen(result.isFullscreen, FullscreenType.Windowed)
  else:
    discard

proc processInput*(game: GameObj): GameObj = 
  result = game
  result.last_commands = result.commands
  var event = defaultEvent 

  while pollEvent(event):
    case event.kind:
    of QuitEvent:
      if result.quitCallback != nil:
        result.quitCallback()
      else:
        # TODO: log it? 
        echo "Trying to quit :("
    of KeyDown:
      let command = event.key.keysym.sym.toCommand
      result.commands[command] = true
      if not event.key.repeat:
        result = result.processSystemCommand(command)
    of KeyUp:
      result.commands[event.key.keysym.sym.toCommand] = false
    of MouseMotion:
      result.mouse.x = event.motion.x
      result.mouse.y = event.motion.y
    of MouseButtonDown:
      case event.button.button:
      of BUTTON_LEFT:
        result.mouse.left = true
        result.commands[Command.Shoot] = true
      of BUTTON_MIDDLE:
        result.mouse.middle = true
      of BUTTON_RIGHT:
        result.mouse.right = true
      of BUTTON_X1:
        result.mouse.x1 = true
      of BUTTON_X2:
        result.mouse.x2 = true
      else: 
        discard
    of MouseButtonup:
      case event.button.button:
      of BUTTON_LEFT:
        result.mouse.left = false
        result.commands[Command.Shoot] = false
      of BUTTON_MIDDLE:
        result.mouse.middle = false
      of BUTTON_RIGHT:
        result.mouse.right = false
      of BUTTON_X1:
        result.mouse.x1 = false
      of BUTTON_X2:
        result.mouse.x2 = false
      else: 
        discard
    else:
      discard

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc update*(game: GameObj, elapsed: float): GameObj = 
  result = systems.handle_updates(game, elapsed)

  # Switch scene
  if result.next_scene != nil:
    if result.next_scene_clear_entities:
      result.em.entities = @[]
      result.next_scene_clear_entities = false
    result = result.next_scene(result)
    result.next_scene = nil
  else:
    result.em.flip()

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc quit*(game: GameObj) = 
  game.renderer.destroy()

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newGame*(
    ren: RendererPtr, size: (cint, cint), 
    fullscreenFn: (proc (isFullscreen: bool, ftype: FullscreenType): void),
    exitFn: (proc())): GameObj = 
  result.renderer = ren
  result.em = newEntityManager()
  result.camera = newCamera(size[0], size[1])
  result.setFullscreen = fullscreenFn
  result.quitCallback = exitFn

  randomize epochTime().int 
  
  discard result.renderer.setDrawColor(110, 132, 174)

  # Set default scene
  result = scenes.intro(result)
  
  # let appDir = getAppDir()
  # result.em.add(newEntity(
  #   newBoundingBoxPhysicsComponent(),
  #   newTextureGraphicsComponent(
  #     result.renderer, 
  #     ren.loadTexture(appDir / "res/img/bg.jpg"), 
  #     rect(-10, -10, 500, 500)),
  #   (500, 500),
  #   (-10, -10),
  #   -1
  # ))
