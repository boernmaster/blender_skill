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

# Cycles light-bounce settings for realistic metals
scene.cycles.use_fast_gi = True
scene.cycles.glossy_bounces = 4
scene.cycles.diffuse_bounces = 4
```

## Saving Scripts

Before executing any scene or material script via the MCP, save it to `scripts/` in the project directory (e.g. `scripts/setup_studio_lighting.py`). This keeps your work reproducible and allows re-running or adjusting the setup without re-generating it from scratch. Update `CLAUDE.md` with any project-specific material names or lighting choices that differ from the defaults here.

## Product Scene Presets

Self-contained camera + lighting + world setups for common professional product visualisations. Each preset assumes the subject is centered at the world origin with its bounding box roughly fitting in a 2 m cube — scale or reposition the subject before applying, or scale the lights/camera proportionally afterwards.

### Shared helpers

```python
import bpy, math

def _clear_scene_lights():
    for obj in [o for o in bpy.data.objects if o.type == 'LIGHT']:
        bpy.data.objects.remove(obj, do_unlink=True)

def _add_area(name, location, rotation, energy, size=2.0, color=(1, 1, 1)):
    bpy.ops.object.light_add(type='AREA', location=location)
    light = bpy.context.object
    light.name = name
    light.rotation_euler = rotation
    light.data.energy = energy
    light.data.size = size
    light.data.color = color
    return light

def _set_camera(location, target=(0, 0, 0.5), lens=50):
    scene = bpy.context.scene
    cam = scene.camera
    if cam is None:
        bpy.ops.object.camera_add(location=location)
        cam = bpy.context.object
        scene.camera = cam
    else:
        cam.location = location
    cam.data.lens = lens
    # Aim at target via TRACK_TO on a temporary empty
    bpy.ops.object.empty_add(location=target)
    aim = bpy.context.object
    aim.name = 'CamAim'
    for c in list(cam.constraints):
        cam.constraints.remove(c)
    track = cam.constraints.new('TRACK_TO')
    track.target = aim
    track.track_axis = 'TRACK_NEGATIVE_Z'
    track.up_axis = 'UP_Y'
    return cam

def _set_world_solid(color, strength=1.0):
    world = bpy.context.scene.world
    world.use_nodes = True
    nodes = world.node_tree.nodes
    nodes.clear()
    bg = nodes.new('ShaderNodeBackground')
    out = nodes.new('ShaderNodeOutputWorld')
    bg.inputs['Color'].default_value = (*color, 1.0)
    bg.inputs['Strength'].default_value = strength
    world.node_tree.links.new(bg.outputs['Background'], out.inputs['Surface'])
```

### Engine / Turbine — Dramatic Hero

For aero engines, ICE engines, gearboxes, turbines. Dark moody backdrop, strong directional key, hard rim for silhouette, low warm fill. Camera low and tight for hero feel.

```python
def setup_engine_hero():
    _clear_scene_lights()
    _set_world_solid((0.015, 0.015, 0.02), strength=0.3)

    # Cool key from upper-front-left
    _add_area('Key',  ( 5, -3, 6), (math.radians( 55), 0, math.radians( 35)),
              energy=1500, size=3.0, color=(1.00, 0.98, 0.95))
    # Hard rim from upper-back-right (separates from black background)
    _add_area('Rim',  (-3,  5, 5), (math.radians(-50), 0, math.radians(-160)),
              energy=900,  size=1.5, color=(0.85, 0.92, 1.00))
    # Warm low fill — gives depth to undersides without lifting blacks
    _add_area('Fill', (-4, -3, 1), (math.radians( 75), 0, math.radians( -50)),
              energy=180,  size=4.0, color=(1.00, 0.82, 0.62))

    # 85 mm lens, 3/4 angle, slightly below subject mid-height
    _set_camera(location=(7, -7, 1.8), target=(0, 0, 1.0), lens=85)
```

### Traction Battery / EV Component — Clean Industrial

For battery packs, inverters, motors, electronics, white-paper renders. Bright neutral environment, broad soft top light, low-contrast fill from all sides, faint shadow for grounding. Camera slightly elevated, mild perspective.

```python
def setup_battery_clean():
    _clear_scene_lights()
    _set_world_solid((0.85, 0.86, 0.88), strength=1.2)

    # Large soft overhead — primary illumination
    _add_area('Top',   (0, 0, 6), (0, 0, 0),
              energy=600, size=8.0)
    # Front fill — flatten shadows
    _add_area('Front', (0, -5, 2), (math.radians(80), 0, 0),
              energy=300, size=5.0)
    # Side wraps — eliminate dark sides
    _add_area('Left',  (-5, 0, 2), (math.radians(80), 0, math.radians(-90)),
              energy=200, size=4.0)
    _add_area('Right', ( 5, 0, 2), (math.radians(80), 0, math.radians( 90)),
              energy=200, size=4.0)

    # 50 mm, slightly elevated 3/4 view, mild perspective
    _set_camera(location=(5, -5, 3), target=(0, 0, 0.5), lens=50)
```

### Educational / Explainer — Even & Neutral

For technical diagrams, training material, instructions, exploded views. Fully even lighting from a sky dome, no harsh shadows, white infinite background. Near-orthographic camera so geometry reads cleanly without perspective distortion.

```python
def setup_educational():
    _clear_scene_lights()
    _set_world_solid((1.0, 1.0, 1.0), strength=2.0)

    # Sun for crisp definition without dominance
    bpy.ops.object.light_add(type='SUN', location=(0, 0, 10))
    sun = bpy.context.object
    sun.name = 'KeySun'
    sun.rotation_euler = (math.radians(35), math.radians(15), math.radians(20))
    sun.data.energy = 2.0

    # Soft top fill to lift shadows
    _add_area('TopFill', (0, 0, 8), (0, 0, 0), energy=400, size=10.0)

    # Long lens far back ≈ orthographic look while keeping perspective camera
    _set_camera(location=(8, -8, 4), target=(0, 0, 0.5), lens=120)
```

### Premium Showcase — Studio Hero

For premium consumer products, marketing renders, packaging shots. Gradient backdrop, strong key with softbox feel, sharp rim, subtle reflection plane, lower camera angle.

```python
def setup_premium_showcase():
    _clear_scene_lights()

    # Gradient world — light top, dark bottom
    world = bpy.context.scene.world
    world.use_nodes = True
    nodes = world.node_tree.nodes
    nodes.clear()
    bg   = nodes.new('ShaderNodeBackground')
    grad = nodes.new('ShaderNodeTexGradient')
    coord = nodes.new('ShaderNodeTexCoord')
    mapn  = nodes.new('ShaderNodeMapping')
    out   = nodes.new('ShaderNodeOutputWorld')
    mapn.inputs['Rotation'].default_value[1] = math.radians(90)
    grad.gradient_type = 'LINEAR'
    bg.inputs['Strength'].default_value = 0.5
    links = world.node_tree.links
    links.new(coord.outputs['Generated'], mapn.inputs['Vector'])
    links.new(mapn.outputs['Vector'], grad.inputs['Vector'])
    links.new(grad.outputs['Color'], bg.inputs['Color'])
    links.new(bg.outputs['Background'], out.inputs['Surface'])

    _add_area('Key',  ( 4, -4, 5), (math.radians( 50), 0, math.radians( 45)),
              energy=900, size=4.0)
    _add_area('Rim',  (-3,  4, 4), (math.radians(-50), 0, math.radians(-150)),
              energy=600, size=1.0)
    _add_area('Fill', (-3, -3, 2), (math.radians( 70), 0, math.radians( -45)),
              energy=120, size=5.0, color=(0.95, 0.97, 1.00))

    _set_camera(location=(6, -6, 1.2), target=(0, 0, 0.6), lens=70)
```

### Choosing a preset

| Subject                                  | Preset                  |
|------------------------------------------|-------------------------|
| Aero / car engine, turbine, gearbox      | `setup_engine_hero`     |
| Traction battery, inverter, motor, PCB   | `setup_battery_clean`   |
| Training material, exploded view, diagram| `setup_educational`     |
| Consumer product, marketing hero         | `setup_premium_showcase`|

All presets pair well with the matching `Cycles` settings in the *Render Quality Settings* section above and the metallic materials defined earlier in this skill.

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
