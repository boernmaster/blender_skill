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

Create a smooth 360° orbit around the scene. The camera is parented to an empty at the scene center; rotating the empty sweeps the camera around it.

```python
import bpy, math

scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 120

# Empty at the scene center acts as the orbit pivot
bpy.ops.object.empty_add(location=(0, 0, 1))
target = bpy.context.object
target.name = 'OrbitTarget'

# Position camera at orbit radius
cam = scene.camera
if cam is None:
    bpy.ops.object.camera_add(location=(8, 0, 3))
    cam = bpy.context.object
    scene.camera = cam
else:
    cam.location = (8, 0, 3)

# Parent camera to the empty so the camera follows its rotation
cam.parent = target
cam.matrix_parent_inverse = target.matrix_world.inverted()

# Aim camera at the empty at all times
constraint = cam.constraints.new('TRACK_TO')
constraint.target = target
constraint.track_axis = 'TRACK_NEGATIVE_Z'
constraint.up_axis = 'UP_Y'

# Keyframe the orbit via empty rotation
target.rotation_euler = (0, 0, 0)
target.keyframe_insert('rotation_euler', frame=1)
target.rotation_euler = (0, 0, math.radians(360))
target.keyframe_insert('rotation_euler', frame=scene.frame_end)

# Linear interpolation for a constant-speed orbit
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

## Saving Scripts

Before executing any render script via the MCP, save it to `scripts/` in the project directory (e.g. `scripts/render_orbit_animation.py`). Update `CLAUDE.md` under `## Custom Settings` with the chosen resolution, sample count, and output path so they persist across sessions.

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

## Lean Iteration Workflow

**Always render at the lowest quality that answers the question being asked.** Each pass exists to validate something specific — don't burn samples until the prior pass has been approved.

### Iteration tiers

| Pass        | Purpose                                  | Samples | Resolution | Frames |
|-------------|------------------------------------------|---------|------------|--------|
| `composition` | Camera framing, layout, basic lighting | 16      | 25%        | 1      |
| `lookdev`     | Materials, light intensity, color      | 32      | 50%        | 1      |
| `motion`      | Animation timing, frame coverage       | 32      | 50%        | every 4th frame |
| `review`      | Stakeholder approval                   | 64      | 100%       | full   |
| `final`       | Hand-off / portfolio                   | 256+    | 100%–200%  | full   |

Promote one tier at a time. If `composition` is rejected, fix it and re-render `composition` — never jump to `lookdev` to "see what it looks like."

### Lean preset helper

```python
import bpy

PRESETS = {
    'composition': {'samples': 16, 'res_pct': 25, 'denoise': True},
    'lookdev':     {'samples': 32, 'res_pct': 50, 'denoise': True},
    'motion':      {'samples': 32, 'res_pct': 50, 'denoise': True},
    'review':      {'samples': 64, 'res_pct': 100, 'denoise': True},
    'final':       {'samples': 256, 'res_pct': 100, 'denoise': True},
    'portfolio':   {'samples': 512, 'res_pct': 200, 'denoise': True},
}

def apply_preset(name):
    p = PRESETS[name]
    scene = bpy.context.scene
    scene.cycles.samples = p['samples']
    scene.cycles.use_denoising = p['denoise']
    scene.render.resolution_percentage = p['res_pct']
    # Persistent data: reuse BVH, shaders, geometry between frames in an animation
    scene.render.use_persistent_data = True
    print(f"[render] preset={name} samples={p['samples']} res={p['res_pct']}%")
```

### Skip frames already rendered

Re-running an animation render after a crash should not redo finished frames.

```python
import bpy, os, re

def render_missing_frames(output_dir, prefix='frame_'):
    scene = bpy.context.scene
    pattern = re.compile(re.escape(prefix) + r'(\d+)\.')
    done = {int(m.group(1)) for f in os.listdir(output_dir) if (m := pattern.match(f))}
    for frame in range(scene.frame_start, scene.frame_end + 1):
        if frame in done:
            continue
        scene.frame_set(frame)
        scene.render.filepath = os.path.join(output_dir, f'{prefix}{frame:04d}.png')
        bpy.ops.render.render(write_still=True)
```

### Animation preview — render every Nth frame

Validate motion timing without rendering 120 frames.

```python
import bpy, os

def render_motion_preview(output_dir, step=4):
    scene = bpy.context.scene
    for frame in range(scene.frame_start, scene.frame_end + 1, step):
        scene.frame_set(frame)
        scene.render.filepath = os.path.join(output_dir, f'preview_{frame:04d}.png')
        bpy.ops.render.render(write_still=True)
```

### Lean defaults to set once per scene

```python
import bpy

scene = bpy.context.scene
# Reuse geometry/shader caches between frames — large speedup for animations
scene.render.use_persistent_data = True
# Adaptive sampling: stop sampling pixels that have already converged
scene.cycles.use_adaptive_sampling = True
scene.cycles.adaptive_threshold = 0.01
# Cap per-tile time so a slow region doesn't dominate
scene.cycles.time_limit = 0  # 0 = no limit; set seconds per frame for hard cap
# Denoiser: OptiX is fastest on NVIDIA, OpenImageDenoise is the highest quality fallback
scene.cycles.denoiser = 'OPTIX'
```

### Workflow checklist

1. Apply `composition` preset → render frame 1 → confirm camera and layout.
2. Apply `lookdev` preset → render frame 1 → confirm materials and lighting.
3. Apply `motion` preset → run `render_motion_preview(step=4)` → confirm timing.
4. Apply `review` preset → run `render_missing_frames(...)` for the full range.
5. Apply `final` preset → re-run `render_missing_frames(...)` only after review sign-off.

