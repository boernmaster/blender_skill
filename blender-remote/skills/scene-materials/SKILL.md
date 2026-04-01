---
name: scene-materials
description: >
  This skill should be used when the user asks to set up a scene, add lighting,
  assign materials, create metallic or realistic materials, set up studio lighting,
  three-point lighting, add an HDRI background, enable ambient occlusion, or
  configure screen-space reflections in Blender.
---

# Scene Setup & Materials

Use the `blender` MCP tools to execute Python code inside Blender. All scene and material operations are done via `bpy` calls sent through the MCP.

## Lighting Setup

### Three-Point Studio Lighting
Standard professional setup: key light (main), fill light (soften shadows), rim light (separate subject from background), and a soft overhead.

```python
import bpy, math

def add_area_light(name, location, rotation_euler, energy, size=2.0):
    bpy.ops.object.light_add(type='AREA', location=location)
    light = bpy.context.object
    light.name = name
    light.rotation_euler = rotation_euler
    light.data.energy = energy
    light.data.size = size
    return light

# Key light — strong, 45° front-left above
add_area_light('Key', (4, -4, 5), (math.radians(60), 0, math.radians(45)), energy=800)

# Fill light — softer, opposite side
add_area_light('Fill', (-4, -3, 3), (math.radians(50), 0, math.radians(-40)), energy=200)

# Rim light — behind subject, creates edge separation
add_area_light('Rim', (0, 5, 4), (math.radians(-45), 0, math.radians(180)), energy=400)

# Overhead soft light
add_area_light('Overhead', (0, 0, 8), (0, 0, 0), energy=150, size=5.0)
```

### HDRI Background (Poly Haven)
Download an HDRI from polyhaven.com (e.g., `studio_small_08_4k.exr`) and apply it:

```python
import bpy

world = bpy.context.scene.world
world.use_nodes = True
nodes = world.node_tree.nodes
nodes.clear()

bg = nodes.new('ShaderNodeBackground')
env = nodes.new('ShaderNodeTexEnvironment')
out = nodes.new('ShaderNodeOutputWorld')

env.image = bpy.data.images.load('/path/to/hdri.exr')
bg.inputs['Strength'].default_value = 1.0

links = world.node_tree.links
links.new(env.outputs['Color'], bg.inputs['Color'])
links.new(bg.outputs['Background'], out.inputs['Surface'])
```

## Material Archetypes

Apply using Cycles principled BSDF. All materials target fully opaque results (no transparency).

### Titanium (compressor blades, spools)
```python
mat = bpy.data.materials.new('Titanium')
mat.use_nodes = True
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (0.62, 0.60, 0.58, 1.0)
bsdf.inputs['Metallic'].default_value = 1.0
bsdf.inputs['Roughness'].default_value = 0.25
bsdf.inputs['Specular IOR Level'].default_value = 0.5
```

### Nickel Superalloy (hot section, turbine)
```python
mat = bpy.data.materials.new('NickelSuperalloy')
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (0.72, 0.68, 0.60, 1.0)
bsdf.inputs['Metallic'].default_value = 1.0
bsdf.inputs['Roughness'].default_value = 0.35
```

### Stainless Steel (casings, structural)
```python
mat = bpy.data.materials.new('StainlessSteel')
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (0.80, 0.80, 0.80, 1.0)
bsdf.inputs['Metallic'].default_value = 1.0
bsdf.inputs['Roughness'].default_value = 0.15
```

### Carbon Composite (fan blades)
```python
mat = bpy.data.materials.new('CarbonComposite')
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (0.08, 0.08, 0.08, 1.0)
bsdf.inputs['Metallic'].default_value = 0.0
bsdf.inputs['Roughness'].default_value = 0.45
bsdf.inputs['Specular IOR Level'].default_value = 0.3
```

### Copper Alloy (combustion components)
```python
mat = bpy.data.materials.new('CopperAlloy')
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (0.72, 0.45, 0.20, 1.0)
bsdf.inputs['Metallic'].default_value = 1.0
bsdf.inputs['Roughness'].default_value = 0.30
```

### Chrome (spinner, polished surfaces)
```python
mat = bpy.data.materials.new('Chrome')
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (0.95, 0.95, 0.95, 1.0)
bsdf.inputs['Metallic'].default_value = 1.0
bsdf.inputs['Roughness'].default_value = 0.05
```

## Assigning Materials to Objects

```python
import bpy

def assign_material(obj_name, mat_name):
    obj = bpy.data.objects.get(obj_name)
    mat = bpy.data.materials.get(mat_name)
    if obj and mat:
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)
```

## Render Quality Settings

Enable ambient occlusion and screen-space reflections for realistic metallic shading:

```python
import bpy

scene = bpy.context.scene
scene.render.engine = 'CYCLES'

# Ambient occlusion via Cycles world shader (baked into render)
scene.world.light_settings.use_ambient_occlusion = True
scene.world.light_settings.ao_factor = 0.3

# Screen-space reflections (EEVEE only; for Cycles use glossy bounces)
scene.cycles.use_fast_gi = True
scene.cycles.glossy_bounces = 4
scene.cycles.diffuse_bounces = 4
```

## Shadow-Catching Ground Plane

```python
import bpy

bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
plane = bpy.context.object
plane.name = 'ShadowPlane'

mat = bpy.data.materials.new('ShadowCatcher')
mat.use_nodes = True
mat.cycles.is_shadow_catcher = True
plane.data.materials.append(mat)
```
