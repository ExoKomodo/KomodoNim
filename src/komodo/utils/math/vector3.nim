from ../private/raylib import nil

type Vector3* = raylib.Vector3

func `*`*(self: Vector3; scale: float32): Vector3 =
  Vector3(
    x: self.x * scale,
    y: self.y * scale,
    z: self.z * scale,
  )

func `*`*(scale: float32; self: Vector3): Vector3 =
  Vector3(
    x: self.x * scale,
    y: self.y * scale,
    z: self.z * scale,
  )