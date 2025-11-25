#!/usr/bin/env python
"""
Blender Wrapper Script for OpenCue

This script is executed by OpenCue render nodes to render individual frames
or frame chunks. It receives frame information from OpenCue environment variables
and executes Blender with the appropriate parameters.
"""

import os
import subprocess
import sys


def main():
    """Main execution function for rendering Blender frames"""
    
    # Get environment variables from OpenCue
    try:
        # CUE_IFRAME is the start frame of the chunk
        start_frame = int(os.environ.get("CUE_IFRAME", "1"))
        # CUE_CHUNK is the chunk size (number of frames in this task)
        chunk_size = int(os.environ.get("CUE_CHUNK", "1"))
    except ValueError as e:
        print(f"Error parsing CUE_IFRAME or CUE_CHUNK: {e}")
        sys.exit(1)

    end_frame = start_frame + chunk_size - 1

    # Arguments passed to this script: blender_exe, blend_file, scene, [use_compositing]
    if len(sys.argv) < 4:
        print("Usage: blender_wrapper.py <blender_exe> <blend_file> <scene> [use_compositing]")
        sys.exit(1)

    blender_exe = sys.argv[1]
    blend_file = sys.argv[2]
    scene = sys.argv[3]
    use_compositing = len(sys.argv) > 4 and sys.argv[4].lower() == "true"

    # Strip quotes from blend_file if present
    blend_file = blend_file.strip('"').strip("'")

    # Validate inputs
    if not os.path.exists(blender_exe):
        print(f"Error: Blender executable not found: {blender_exe}")
        sys.exit(1)
    
    if not os.path.exists(blend_file):
        print(f"Error: Blend file not found: {blend_file}")
        sys.exit(1)

    # Construct Blender command
    # blender -b <file> -S <scene> -s <start> -e <end> -a
    cmd = [
        blender_exe,
        "-b", blend_file,
        "-S", scene,
        "-s", str(start_frame),
        "-e", str(end_frame),
    ]
    
    # Add compositing flag if requested
    if use_compositing:
        cmd.append("--use-compositing")
    
    # Add animation render flag
    cmd.append("-a")

    print("=" * 80)
    print("OpenCue Blender Wrapper")
    print("=" * 80)
    print(f"Blender Executable: {blender_exe}")
    print(f"Blend File: {blend_file}")
    print(f"Scene: {scene}")
    print(f"Frame Range: {start_frame} - {end_frame}")
    print(f"Chunk Size: {chunk_size}")
    print(f"Use Compositing: {use_compositing}")
    print("=" * 80)
    print(f"Executing: {' '.join(cmd)}")
    print("=" * 80)
    sys.stdout.flush()

    # Execute Blender
    try:
        ret = subprocess.call(cmd)
        
        if ret == 0:
            print("=" * 80)
            print(f"Successfully rendered frames {start_frame}-{end_frame}")
            print("=" * 80)
        else:
            print("=" * 80)
            print(f"Blender exited with error code: {ret}")
            print("=" * 80)
        
        sys.exit(ret)
        
    except Exception as e:
        print("=" * 80)
        print(f"Failed to execute Blender: {e}")
        print("=" * 80)
        sys.exit(1)


if __name__ == "__main__":
    main()
