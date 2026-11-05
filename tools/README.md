# Tools — script destination

The locally reported `comfy.py`, `blender_process.py`, `resmon.sh` and `comfy_start.sh` must be reviewed, imported, and verified by Goose. They have **not** been invented or reimplemented as part of this repository documentation change.

Scripts must respect active-user resource headroom, prevent duplicate ComfyUI servers, and monitor **during** jobs rather than only at startup. Do not commit private paths, logs or credentials.
