---
name: rendering
description: >
  This skill should be used when the user asks to render, set up rendering,
  enable CUDA, configure Cycles, set render resolution or samples, render an
  animation, output a PNG or EXR, create an animated GIF, or combine rendered
  frames into a video or GIF in Blender.
---

# Rendering with Cycles + CUDA

## Enable Cycles and CUDA GPU

```python
import bpy

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'GPU'

cprefs = bpy.context.preferences.addons['cycles'].preferences
cprefs.compute_device_type = 'CUDA'
cprefs.get_devices()

for device in cprefs.devices:
    device.use = (device.type == 'CUDA')

enabled = [d.name for d in cprefs.devices if d.use]
print("Rendering on:", enabled)
```

If `nvidia-smi` shows the GPU but Cycles doesn't detect it, re-run `cprefs.get_devices()` after setting `compute_device_type`.

## Render Settings

```python
import bpy

scene = bpy.context.scene
render = scene.render

# Resolution
render.resolution_x = 1920
render.resolution_y = 1080
render.resolution_percentage = 100

# Sampling (lower for drafts, higher for final)
scene.cycles.samples = 128          # final quality
scene.cycles.use_denoising = True   # AI denoiser reduces noise at lower samples

# Output format
render.image_settings.file_format = 'PNG'
render.image_settings.color_mode = 'RGBA'
render.filepath = '/tmp/render_output.png'
```

## Render a Single Frame

```python
import bpy

bpy.context.scene.frame_set(1)
bpy.ops.render.render(write_still=True)
print("Rendered:", bpy.context.scene.render.filepath)
```

## Render an Animation

```python
import bpy

scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 120           # 5 seconds at 24fps
scene.render.fps = 24

scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = '/tmp/frames/frame_'   # Blender appends #### suffix

bpy.ops.render.render(animation=True)
print("Animation rendered to:", scene.render.filepath)
```

## Camera Animation — Cinematic Orbit

Create a smooth 360° orbit around the scene:

```python
import bpy, math

scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 120

# Create empty at scene center as orbit target
bpy.ops.object.empty_add(location=(0, 0, 1))
target = bpy.context.object
target.name = 'OrbitTarget'

# Position camera
cam = scene.camera
if cam is None:
    bpy.ops.object.camera_add(location=(8, 0, 3))
    cam = bpy.context.object
    scene.camera = cam

# Aim camera at target
constraint = cam.constraints.new('TRACK_TO')
constraint.target = target
constraint.track_axis = 'TRACK_NEGATIVE_Z'
constraint.up_axis = 'UP_Y'

# Keyframe the orbit via empty rotation
target.rotation_euler = (0, 0, 0)
target.keyframe_insert('rotation_euler', frame=1)
target.rotation_euler = (0, 0, math.radians(360))
target.keyframe_insert('rotation_euler', frame=120)

# Use linear interpolation for smooth orbit
for fcurve in target.animation_data.action.fcurves:
    for kp in fcurve.keyframe_points:
        kp.interpolation = 'LINEAR'
```

## Convert Frames to GIF

After rendering PNG frames, combine them with ImageMagick or Pillow:

### With ImageMagick (shell)
```bash
convert -delay 4 -loop 0 /tmp/frames/frame_*.png /tmp/output.gif
# -delay 4 = ~25fps; adjust to match render fps
```

### With Pillow (Python, already available in venv)
```python
from PIL import Image
import glob, os

frame_paths = sorted(glob.glob('/tmp/frames/frame_*.png'))
frames = [Image.open(f).convert('RGBA') for f in frame_paths]

frames[0].save(
    '/tmp/output.gif',
    save_all=True,
    append_images=frames[1:],
    loop=0,
    duration=42,   # ms per frame (~24fps)
    optimize=True
)
print(f"GIF saved: {len(frames)} frames")
```

## Save the Blender File

```python
import bpy
bpy.ops.wm.save_as_mainfile(filepath='/tmp/scene.blend')
```

## Quick Render Quality Presets

| Use case       | Samples | Denoising | Resolution |
|----------------|---------|-----------|------------|
| Draft / preview | 32     | True      | 50%        |
| Review          | 64     | True      | 100%       |
| Final           | 256    | True      | 100%       |
| Print/portfolio | 512    | True      | 200%       |

```python
# Draft preset
scene.cycles.samples = 32
scene.render.resolution_percentage = 50

# Final preset
scene.cycles.samples = 256
scene.render.resolution_percentage = 100
```
