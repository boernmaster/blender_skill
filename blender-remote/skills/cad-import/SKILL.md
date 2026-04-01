---
name: cad-import
description: >
  This skill should be used when the user asks to import STP, STEP, STL, OBJ,
  FBX, or GLTF files into Blender, load a CAD assembly, import files from a
  folder, read an Excel BOM spreadsheet to map parts to materials, or work
  with CAD geometry in Blender. Also use when the user mentions a .stp or
  .step file.
---

# CAD File Import

## STP / STEP Files — Important Limitation

Blender cannot natively import STP/STEP files. Convert first using FreeCAD (free) or another CAD tool:

1. Open the `.stp` file in FreeCAD
2. Select all parts → File → Export → choose **GLTF/GLB**, **OBJ**, or **FBX**
3. Import the exported file into Blender (see below)

GLTF/GLB is preferred — it preserves hierarchy and is lossless.

Alternative: online converters (CAD Exchanger, Convertio) can convert STP → OBJ/FBX without installing software.

## STL Import (via blender-remote MCP)

```python
import bpy

# Single STL file
bpy.ops.wm.stl_import(filepath='/path/to/part.stl')

# Rename imported object
imported = bpy.context.selected_objects[-1]
imported.name = 'PartName'
```

### Batch Import All STL Files from a Folder

```python
import bpy, os

folder = '/path/to/stl_folder'
for filename in sorted(os.listdir(folder)):
    if filename.lower().endswith('.stl'):
        filepath = os.path.join(folder, filename)
        bpy.ops.wm.stl_import(filepath=filepath)
        obj = bpy.context.selected_objects[-1]
        obj.name = os.path.splitext(filename)[0]
        print(f"Imported: {obj.name}")
```

## OBJ / FBX / GLTF Import

```python
import bpy

# OBJ
bpy.ops.wm.obj_import(filepath='/path/to/model.obj')

# FBX
bpy.ops.import_scene.fbx(filepath='/path/to/model.fbx')

# GLTF / GLB
bpy.ops.import_scene.gltf(filepath='/path/to/model.glb')
```

## Reading an Excel BOM with openpyxl

`openpyxl` is already a project dependency. Use it to read part-to-material mappings from an Excel file, then apply materials automatically.

```python
import openpyxl

def read_bom(filepath):
    """Returns a dict: {part_name: material_category}"""
    wb = openpyxl.load_workbook(filepath)
    ws = wb.active
    bom = {}
    for row in ws.iter_rows(min_row=2, values_only=True):
        part_name, material_category = row[0], row[1]
        if part_name:
            bom[str(part_name).strip()] = str(material_category).strip()
    return bom
```

## Full Workflow: Import STL + Apply BOM Materials

```python
import bpy, os, openpyxl

# 1. Read BOM
def read_bom(filepath):
    wb = openpyxl.load_workbook(filepath)
    ws = wb.active
    return {
        str(row[0]).strip(): str(row[1]).strip()
        for row in ws.iter_rows(min_row=2, values_only=True)
        if row[0]
    }

# Material category → Blender material name mapping
MATERIAL_MAP = {
    'titanium': 'Titanium',
    'nickel superalloy': 'NickelSuperalloy',
    'stainless steel': 'StainlessSteel',
    'carbon composite': 'CarbonComposite',
    'copper alloy': 'CopperAlloy',
    'chrome': 'Chrome',
}

# 2. Import all STL files
stl_folder = '/path/to/stl_files'
bom_file = '/path/to/bom.xlsx'

bom = read_bom(bom_file)

for filename in sorted(os.listdir(stl_folder)):
    if filename.lower().endswith('.stl'):
        filepath = os.path.join(stl_folder, filename)
        bpy.ops.wm.stl_import(filepath=filepath)
        obj = bpy.context.selected_objects[-1]
        part_name = os.path.splitext(filename)[0]
        obj.name = part_name

        # 3. Assign material from BOM
        category = bom.get(part_name, '').lower()
        mat_name = MATERIAL_MAP.get(category)
        if mat_name:
            mat = bpy.data.materials.get(mat_name)
            if mat:
                if obj.data.materials:
                    obj.data.materials[0] = mat
                else:
                    obj.data.materials.append(mat)
            else:
                print(f"Material not found: {mat_name}")
        else:
            print(f"No BOM entry for: {part_name}")
```

## Centering and Framing Imported Assembly

After import, center the assembly and frame it in the camera view:

```python
import bpy

# Select all mesh objects
bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        obj.select_set(True)

# Move to world origin
bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
bpy.ops.object.location_clear()

# Frame in view
bpy.ops.view3d.camera_to_view_selected()
```
