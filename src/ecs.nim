import 
  random,
  algorithm,
  tables,
  typetraits

type
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
    
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

# Some helper functions

proc typename[T](sym: T): string = 
  ## Returns the type of a variable passed into it.
  ## A simple helper method
  sym.type.name

proc type_to_string*(t: typedesc): string = 
  ## Returns the name of a type that is passed. Use as:
  ## 
  ## .. code-block:: Nim 
  ##   type_to_string(int)
  t.name

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Entity
proc newEntity*(x, y, w, h: int, z: int = 0, name: string = nil): Entity = 
  ## Create a new entity.
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
  ## Add a component to an entity. This function allows chaining, so it's easy 
  ## to do things like: 
  ##
  ## .. code-block:: Nim
  ##   let e = newEntity(0, 0, 10, 10).add(newComp1()).add(newComp2())
  result = this
  result.components[component.typename] = component

proc remove*(this: Entity, comp_type: typedesc) =
  ## Removes a specific component from the entity
  ##   Usage: entity.remove(Comp1)
  let name = comp_type.name
  if this.components.contains(name):
    this.components.del(name)

proc get*[T: Component](this: Entity, component_type: typedesc[T]): T =
  ## Get a component by use of the type 
  ##   Usage: let c = entity.get(Comp1) 
  T(this.components[component_type.name])

proc has*(this: Entity, types: varargs[string, `type_to_string`]): bool =
  ## Procedure to check if the entity has the specified type(s)
  ##   Usage: if entity.has(Comp1, Comp2) and not entity.has(Comp3): ...
  for t in types:
    if not this.components.contains t: return false
  true

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> EntityManager
proc newEntityManager*(): EntityManager = 
  ## Create a new entitymanager 
  new result
  result.entities = @[]

proc add*(em: var EntityManager, e: Entity) =
  ## Add an entity to the entitymanager. 
  ## Entities will be sorted based on their z, to make rendering easier
  em.entities.add(e)
  em.entities = em.entities.sortedByIt it.z