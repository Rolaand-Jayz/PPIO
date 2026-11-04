"""Validate current Blender mesh selection and export a GLB. Run after -- in Blender."""
import argparse
import json
import math
from pathlib import Path
import sys

import bpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, help="destination .glb")
    parser.add_argument("--attachment", action="append", default=[], help="required named Empty attachment point")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    meshes = [obj for obj in bpy.context.selected_objects if obj.type == "MESH"]
    if not meshes:
        raise SystemExit("validation failed: select at least one mesh")
    failures = []
    report = {"meshes": [], "attachments": [], "warnings": []}
    for obj in meshes:
        if not all(math.isfinite(value) for value in (*obj.dimensions, *obj.location)):
            failures.append(f"{obj.name}: non-finite transform")
        if len(obj.data.polygons) == 0:
            failures.append(f"{obj.name}: no faces")
        boundary = sum(1 for edge in obj.data.edges if len(edge.vertices) and edge.is_loose)
        if boundary:
            report["warnings"].append(f"{obj.name}: {boundary} loose edges")
        if not obj.data.materials:
            report["warnings"].append(f"{obj.name}: no material assigned")
        report["meshes"].append({"name": obj.name, "vertices": len(obj.data.vertices), "faces": len(obj.data.polygons), "dimensions": list(obj.dimensions), "materials": [m.name if m else None for m in obj.data.materials]})
    for name in args.attachment:
        point = bpy.data.objects.get(name)
        if point is None or point.type != "EMPTY":
            failures.append(f"required attachment Empty missing: {name}")
        else:
            report["attachments"].append(name)
    if failures:
        raise SystemExit("validation failed:\n" + "\n".join(failures))
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", use_selection=True)
    if not output.is_file() or output.stat().st_size == 0:
        raise SystemExit("export failed: missing or empty GLB")
    report["export"] = str(output)
    report["bytes"] = output.stat().st_size
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
