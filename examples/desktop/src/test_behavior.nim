import options

import komodo/ecs/components/[
    behavior_macros,
    component,
    transform_component,
]
import komodo/ecs/entity
import komodo/ecs/systems/system
import komodo/input
import komodo/lib/math
import komodo/logging

from komodo/game import executeOnSystems, instance

behavior TestBehavior:
  fields:
    transform: Option[TransformComponent]
    action: Action

  create:
    discard

  init:
    var transform = none[TransformComponent]()
    let game = instance.get()
    game.executeOnSystems(proc (system: System) =
      if transform.isNone():
        transform = system.findComponentByParent[:TransformComponent](
          self.parent.get().id,
        )
    )
    if transform.isNone():
      logError("Failed to find transform")
      return
    self.transform = transform

    self.action = newAction("move")
    self.action
      .map(MouseButtons.Left)
      .map(Keys.Space)

  update:
    if self.action.isDown():
      let position = self.transform.get.position
      self.transform.get.position = Vector3(
          x: position.x + 1,
          y: position.y,
          z: position.z,
      )

  destroy:
    discard
