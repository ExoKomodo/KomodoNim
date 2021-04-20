import ./entity
import ./lib/math/vector3
import ./lib/logging
import ./rendering/[
  drawable,
  resource_cache,
]
import ./rendering/private/[
  image_rendering,
  text_rendering,
]

import strformat

export drawable
export entity
export resource_cache


proc draw*(
  drawable: Drawable;
  cache: ResourceCache;
  root_position: Vector3 = Vector3();
) {.sideEffect.} =
  case drawable.kind:
    of DrawableKind.image:
      image_rendering.draw(
        drawable,
        cache,
        root_position=root_position,
      )
    of DrawableKind.text:
      text_rendering.draw(
        drawable,
        cache,
        root_position=root_position,
      )

proc draw*(
  entity: Entity;
  cache: ResourceCache;
) {.sideEffect.} =
  for drawable in entity.drawables:
    drawable.draw(
      cache,
      root_position=entity.position,
    )

