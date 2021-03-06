import macros

import ../../private/macro_helpers
import ../../lib/graphics/camera
import ./system

export camera
export system


type InteractiveMethod {.pure.} = enum
  Draw
  Update

proc generateSystemConstructor(
    typeName: NimNode;
    constructorDefinition: NimNode;
): NimNode =
  expectKind(typeName, nnkIdent)
  expectKind(constructorDefinition, nnkCall)
  let constructorSignature = constructorDefinition[0]
  let constructorBody = constructorDefinition[1]
  expectKind(constructorBody, nnkStmtList)

  let formalParams = generateFormalParams(typeName, constructorSignature)

  let defaultStatements = newStmtList(
      (
          quote do:
        result = `typeName`()
      ),
  )
  result = generateConstructor(
      typeName,
      formalParams,
      defaultStatements,
      constructorBody,
  )

proc generateDrawOrUpdate(typeName: NimNode; procDefinition: NimNode): NimNode =
  expectKind(typeName, nnkIdent)
  let procSignature = procDefinition[0]

  let methodType = case $procSignature:
  of "draw":
    InteractiveMethod.Draw
  of "update":
    InteractiveMethod.Update
  else:
    raiseAssert("Must contain either draw or update block")

  let procBody = procDefinition[1]
  expectKind(procBody, nnkStmtList)

  let formalParams = newTree(
      nnkFormalParams,
      newEmptyNode(),
      newTree(
          nnkIdentDefs,
          ident("self"),
          ident($typeName),
          newEmptyNode(),
    ),
  )
  case methodType:
  of InteractiveMethod.Draw:
    formalParams.add(
        newTree(
            nnkIdentDefs,
            ident("injected_camera"),
            ident("Camera"),
            newEmptyNode(),
      ),
    )
  of InteractiveMethod.Update:
    formalParams.add(
        newTree(
            nnkIdentDefs,
            ident("delta"),
            ident("float32"),
            newEmptyNode(),
      ),
    )


  result = newTree(
      nnkMethodDef,
      newTree(
          nnkPostfix,
          ident("*"),
          ident($procSignature),
    ),
    newEmptyNode(),
    newEmptyNode(),
    formalParams,
    newEmptyNode(),
    newEmptyNode(),
    quote do:
      `procBody`
  )

macro system*(typeName: untyped; statements: untyped): untyped =
  result = newStmtList()
  expectKind(statements, nnkStmtList)
  let typeDefinition = generateTypeDefinition(
      typeName,
      statements[0],
      "System",
  )
  let constructor = generateSystemConstructor(
      typeName,
      statements[1],
  )
  let initializer = generateInit(
      typeName,
      statements[2],
      (
          quote do:
        procCall self.System.initialize()
      ),
      unknownLockLevel(),
  )
  let drawOrUpdate = generateDrawOrUpdate(
      typeName,
      statements[3],
  )
  let destructor = generateDestructor(
      typeName,
      statements[4],
      quote do:
    self.destroy()
  )
  result.add(typeDefinition)
  result.add(destructor)
  result.add(constructor)
  result.add(initializer)
  result.add(drawOrUpdate)
