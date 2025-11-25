#!/usr/bin/env python
"""
OpenCue Job Submission Script for Blender

This script is called by the Blender add-on to create and submit
render jobs to the OpenCue render farm using pyoutline.
"""

import argparse
import getpass
import os
import sys
from datetime import datetime


def submit_job(args):
    """Submit a Blender render job to OpenCue"""
    
    # Import OpenCue libraries
    try:
        import outline
        import outline.cuerun
        import outline.modules.shell
    except ImportError as e:
        print(f"Error: Failed to import OpenCue libraries: {e}")
        print("Please ensure pycue and pyoutline are installed in your Python environment")
        sys.exit(1)
    
    # Validate inputs
    if not os.path.exists(args.blend_file):
        print(f"Error: Blend file not found: {args.blend_file}")
        sys.exit(1)
    
    if not os.path.exists(args.wrapper_script):
        print(f"Error: Wrapper script not found: {args.wrapper_script}")
        sys.exit(1)
    
    # Determine Blender executable
    blender_exe = args.blender_exe
    if not blender_exe:
        # Try to find Blender in common locations
        common_paths = [
            r"C:\Program Files\Blender Foundation\Blender\blender.exe",
            r"C:\blender\blender.exe",
            "blender",  # Try PATH
        ]
        
        for path in common_paths:
            if os.path.exists(path):
                blender_exe = path
                break
        
        if not blender_exe:
            blender_exe = "blender"  # Fallback to PATH
    
    # Get Python executable (current interpreter)
    python_exe = sys.executable
    
    # Construct command for the wrapper
    # python wrapper.py <blender_exe> <blend_file> <scene> <use_compositing>
    command = [
        python_exe,
        args.wrapper_script,
        blender_exe,
        f'"{args.blend_file}"',  # Quote the path in case of spaces
        args.scene,
        "true" if args.use_compositing else "false"
    ]
    
    # Create OpenCue job outline
    print("=" * 80)
    print("Creating OpenCue Job")
    print("=" * 80)
    print(f"Job Name: {args.job_name}")
    print(f"Show: {args.show}")
    print(f"Shot: {args.shot}")
    print(f"Frame Range: {args.frame_range}")
    print(f"Chunk Size: {args.chunk_size}")
    print(f"Cores per Task: {args.cores}")
    print(f"Memory per Task: {args.memory} MB")
    print(f"Max Cores (Job): {args.max_cores if args.max_cores > 0 else 'Unlimited'}")
    print("=" * 80)
    
    try:
        # Create job outline
        ol = outline.Outline(
            args.job_name,
            shot=args.shot,
            show=args.show,
            user=getpass.getuser()
        )
        
        # Set job-level resource limits
        if args.max_cores > 0:
            ol.set_maxcores(args.max_cores)
        
        # Create render layer
        layer = outline.modules.shell.Shell(
            'render',
            command=command,
            chunk=args.chunk_size,
            cores=args.cores,
            range=args.frame_range
        )
        
        # Set layer-level resource limits
        layer.set_arg("cores", args.cores)
        layer.set_arg("memory", args.memory)
        
        # Add layer to job
        ol.add_layer(layer)
        
        # Launch job to OpenCue
        print("Submitting job to OpenCue...")
        outline.cuerun.launch(ol, use_pycuerun=False)
        
        print("=" * 80)
        print(f"Successfully submitted job: {args.job_name}")
        print("=" * 80)
        
        return 0
        
    except Exception as e:
        print("=" * 80)
        print(f"Error submitting job: {e}")
        print("=" * 80)
        import traceback
        traceback.print_exc()
        return 1


def main():
    """Parse arguments and submit job"""
    
    parser = argparse.ArgumentParser(
        description="Submit Blender render job to OpenCue"
    )
    
    # Required arguments
    parser.add_argument(
        "--blend-file",
        required=True,
        help="Path to the Blender file (.blend)"
    )
    
    parser.add_argument(
        "--scene",
        required=True,
        help="Scene name to render"
    )
    
    parser.add_argument(
        "--frame-range",
        required=True,
        help="Frame range to render (e.g., '1-100')"
    )
    
    parser.add_argument(
        "--job-name",
        required=True,
        help="Name for the OpenCue job"
    )
    
    parser.add_argument(
        "--show",
        required=True,
        help="Show name for OpenCue"
    )
    
    parser.add_argument(
        "--shot",
        required=True,
        help="Shot name for OpenCue"
    )
    
    parser.add_argument(
        "--wrapper-script",
        required=True,
        help="Path to blender_wrapper.py script"
    )
    
    # Optional arguments
    parser.add_argument(
        "--blender-exe",
        default="",
        help="Path to Blender executable (auto-detected if not specified)"
    )
    
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=1,
        help="Number of frames per task (default: 1)"
    )
    
    parser.add_argument(
        "--cores",
        type=int,
        default=4,
        help="Number of CPU cores per task (default: 4)"
    )
    
    parser.add_argument(
        "--memory",
        type=int,
        default=4096,
        help="Memory allocation per task in MB (default: 4096)"
    )
    
    parser.add_argument(
        "--max-cores",
        type=int,
        default=0,
        help="Maximum cores for entire job, 0 = unlimited (default: 0)"
    )
    
    parser.add_argument(
        "--use-compositing",
        action="store_true",
        help="Enable compositor nodes for rendering"
    )
    
    args = parser.parse_args()
    
    # Submit the job
    exit_code = submit_job(args)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
