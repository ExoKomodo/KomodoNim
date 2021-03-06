{.used.}
import options
import sequtils
import tables

from sugar import `=>`

import ../components
import ../entity
import ../ids
import ../../lib/graphics/camera


type
  SystemObj = object of RootObj
    entityToComponents: Table[EntityId, seq[Component]]
    initialized: bool
    uninitializedComponents: seq[Component]

  System* = ref SystemObj

func deregisterComponent*(self: System; component: Component): bool {.locks: 0.} =
  if component.parent.isNone:
    return false

  let parent = component.parent.get()
  if not (parent.id in self.entityToComponents):
    return false

  var components = self.entityToComponents[parent.id]
  components.keepIf(_ => _ != component)
  return true

func deregisterEntity*(self: System; entity: Entity): bool {.locks: 0.} =
  if not (entity.id in self.entityToComponents):
    return false
  self.entityToComponents.del(entity.id)
  true

func destroy*(self: var SystemObj) =
  self.entityToComponents.clear()
  self.uninitializedComponents = @[]

func entityToComponents*(self: System): Table[EntityId, seq[Component]] {.inline, locks: 0.}
    = self.entityToComponents

func findComponentByParent*[T: Component](
    self: System;
    parentId: EntityId;
): Option[T] {.locks: 0.} =
  if not self.entityToComponents.hasKey(parentId):
    return none[T]()
  let components = self.entityToComponents[parentId]
  for component in components:
    if component of T:
      return some[T](T(component))
  return none[T]()

func findComponentByParent*[T: Component](self: System; parent: Entity): Option[T] {.locks: 0.} =
  self.findComponentByParent[:T](parent.id)

method hasNecessaryComponents*(
    self: System;
    entity: Entity;
    components: seq[Component];
): bool {.base, locks: 0.} = false

func isInitialized*(self: SystemObj | System): bool {.inline, locks: 0.}
    = self.initialized

method initialize*(self: System) {.base, locks: 0.} =
  for component in self.uninitializedComponents:
    if (
      component.isInitialized or
      component.parent.isNone or
      not (component.parent.unsafeGet().id in self.entityToComponents)
    ):
      continue
    component.initialize()
  self.uninitializedComponents = @[]
  self.initialized = true

func registerComponent*(self: System; component: Component): bool {.locks: 0.} =
  if component.parent.isNone:
    return false

  let parent = component.parent.get()
  if not (parent.id in self.entityToComponents):
    self.entityToComponents[parent.id] = @[]

  let components = self.entityToComponents[parent.id]
  if components.any(_ => _.id == component.id):
    return false

  self.entityToComponents[parent.id] &= component
  if not component.isInitialized:
    self.uninitializedComponents &= component
  return true

func refreshEntityRegistration*(self: System; entity: Entity) {.locks: 0.} =
  if not (entity.id in self.entityToComponents):
    return
  let components = self.entityToComponents[entity.id]
  if not self.hasNecessaryComponents(entity, components):
    return
  self.entityToComponents.del(entity.id)

  for component in components:
    discard self.registerComponent(component)

func registerEntity*(
  self: System;
  entity: Entity;
  componentStore: Table[ComponentId, Component];
): bool {.locks: 0.} =
  if entity.id in self.entityToComponents:
    return false

  self.entityToComponents[entity.id] = @[]
  for component in componentStore.values:
    if component.parent.isSome and component.parent.unsafeGet().id == entity.id:
      discard self.registerComponent(component)

  self.refreshEntityRegistration(entity)
  return true

method draw*(self: System; injected_camera: Camera) {.base.} =
  discard

method update*(self: System; delta: float32) {.base.} =
  discard
