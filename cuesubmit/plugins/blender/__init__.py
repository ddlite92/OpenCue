#  Copyright Contributors to the OpenCue Project
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

"""
Blender Add-on for OpenCue Render Farm Submission

This add-on allows users to submit Blender render jobs directly to an OpenCue
render farm from within Blender's UI.
"""

import bpy
import os
import sys
import subprocess
import getpass
from datetime import datetime
from bpy.types import Operator, Panel, AddonPreferences, PropertyGroup
from bpy.props import StringProperty, IntProperty, BoolProperty, PointerProperty

bl_info = {
    "name": "OpenCue Farm Submit",
    "author": "OpenCue Contributors",
    "version": (1, 0, 0),
    "blender": (3, 0, 0),
    "location": "View3D > Sidebar > OpenCue Tab",
    "description": "Submit Blender render jobs to OpenCue render farm",
    "category": "Render",
    "doc_url": "https://github.com/AcademySoftwareFoundation/OpenCue",
    "tracker_url": "https://github.com/AcademySoftwareFoundation/OpenCue/issues",
}


# ============================================================================
# Property Groups
# ============================================================================

class OpenCueJobProperties(PropertyGroup):
    """Properties for OpenCue job submission"""
    
    job_name: StringProperty(
        name="Job Name",
        description="Name for the OpenCue job",
        default="blender_job"
    )
    
    show: StringProperty(
        name="Show",
        description="Show name for OpenCue",
        default="testing"
    )
    
    shot: StringProperty(
        name="Shot",
        description="Shot name for OpenCue",
        default="default_shot"
    )
    
    frame_start: IntProperty(
        name="Start Frame",
        description="First frame to render",
        default=1,
        min=0
    )
    
    frame_end: IntProperty(
        name="End Frame",
        description="Last frame to render",
        default=250,
        min=0
    )
    
    chunk_size: IntProperty(
        name="Chunk Size",
        description="Number of frames per task",
        default=1,
        min=1,
        max=100
    )
    
    cores: IntProperty(
        name="Cores",
        description="Number of CPU cores per task",
        default=4,
        min=1,
        max=128
    )
    
    memory: IntProperty(
        name="Memory (MB)",
        description="Memory allocation per task in megabytes",
        default=4096,
        min=512,
        max=65536
    )
    
    use_compositing: BoolProperty(
        name="Use Compositing",
        description="Enable compositor nodes for rendering",
        default=True
    )
    
    max_cores: IntProperty(
        name="Max Cores (Job)",
        description="Maximum cores for entire job (0 = unlimited)",
        default=0,
        min=0,
        max=1000
    )


# ============================================================================
# Add-on Preferences
# ============================================================================

class OpenCueAddonPreferences(AddonPreferences):
    """Preferences for OpenCue add-on"""
    bl_idname = __name__
    
    python_executable: StringProperty(
        name="Python Executable",
        description="Path to Python executable with OpenCue libraries installed",
        default=r"C:\Users\MON188\Pictures\SS_Dd\Script\ScriptPY\scriptVenv\Scripts\python.exe",
        subtype='FILE_PATH'
    )
    
    wrapper_script: StringProperty(
        name="Wrapper Script",
        description="Path to blender_wrapper.py script",
        default=r"C:\Users\MON188\Pictures\SS_Dd\Script\Github\OpenCue\cuesubmit\plugins\blender\blender_wrapper.py",
        subtype='FILE_PATH'
    )
    
    submission_script: StringProperty(
        name="Submission Script",
        description="Path to submit_job.py script",
        default=r"C:\Users\MON188\Pictures\SS_Dd\Script\Github\OpenCue\cuesubmit\plugins\blender\submit_job.py",
        subtype='FILE_PATH'
    )
    
    default_show: StringProperty(
        name="Default Show",
        description="Default show name",
        default="testing"
    )
    
    default_cores: IntProperty(
        name="Default Cores",
        description="Default number of cores per task",
        default=4,
        min=1
    )
    
    default_memory: IntProperty(
        name="Default Memory (MB)",
        description="Default memory allocation in MB",
        default=4096,
        min=512
    )
    
    def draw(self, context):
        layout = self.layout
        
        box = layout.box()
        box.label(text="OpenCue Paths:", icon='FILE_FOLDER')
        box.prop(self, "python_executable")
        box.prop(self, "wrapper_script")
        box.prop(self, "submission_script")
        
        box = layout.box()
        box.label(text="Default Settings:", icon='PREFERENCES')
        box.prop(self, "default_show")
        box.prop(self, "default_cores")
        box.prop(self, "default_memory")


# ============================================================================
# Operators
# ============================================================================

class OPENCUE_OT_submit_job(Operator):
    """Submit current Blender scene to OpenCue render farm"""
    bl_idname = "opencue.submit_job"
    bl_label = "Submit to OpenCue"
    bl_description = "Submit the current scene to OpenCue render farm"
    bl_options = {'REGISTER'}
    
    def execute(self, context):
        scene = context.scene
        props = scene.opencue_props
        prefs = context.preferences.addons[__name__].preferences
        
        # Validate scene is saved
        if not bpy.data.filepath:
            self.report({'ERROR'}, "Please save your Blender file before submitting")
            return {'CANCELLED'}
        
        # Validate frame range
        if props.frame_start > props.frame_end:
            self.report({'ERROR'}, "Start frame must be less than or equal to end frame")
            return {'CANCELLED'}
        
        # Validate paths exist
        if not os.path.exists(prefs.python_executable):
            self.report({'ERROR'}, f"Python executable not found: {prefs.python_executable}")
            return {'CANCELLED'}
        
        if not os.path.exists(prefs.submission_script):
            self.report({'ERROR'}, f"Submission script not found: {prefs.submission_script}")
            return {'CANCELLED'}
        
        # Get current scene information
        blend_file = bpy.data.filepath
        scene_name = scene.name
        
        # Build frame range string
        frame_range = f"{props.frame_start}-{props.frame_end}"
        
        # Generate job name with timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        job_name = f"{props.job_name}_{timestamp}" if props.job_name else f"blender_job_{timestamp}"
        
        # Prepare submission command
        # The submission script will handle the actual job creation
        cmd = [
            prefs.python_executable,
            prefs.submission_script,
            "--blend-file", blend_file,
            "--scene", scene_name,
            "--frame-range", frame_range,
            "--job-name", job_name,
            "--show", props.show,
            "--shot", props.shot,
            "--chunk-size", str(props.chunk_size),
            "--cores", str(props.cores),
            "--memory", str(props.memory),
            "--wrapper-script", prefs.wrapper_script,
        ]
        
        if props.max_cores > 0:
            cmd.extend(["--max-cores", str(props.max_cores)])
        
        if props.use_compositing:
            cmd.append("--use-compositing")
        
        # Execute submission
        try:
            self.report({'INFO'}, f"Submitting job: {job_name}")
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.report({'INFO'}, f"Successfully submitted job: {job_name}")
                # Print output to console
                print("OpenCue Submission Output:")
                print(result.stdout)
                return {'FINISHED'}
            else:
                self.report({'ERROR'}, f"Submission failed: {result.stderr}")
                print("OpenCue Submission Error:")
                print(result.stderr)
                return {'CANCELLED'}
                
        except subprocess.TimeoutExpired:
            self.report({'ERROR'}, "Submission timed out after 30 seconds")
            return {'CANCELLED'}
        except Exception as e:
            self.report({'ERROR'}, f"Submission error: {str(e)}")
            return {'CANCELLED'}


class OPENCUE_OT_reset_to_scene(Operator):
    """Reset frame range to match scene settings"""
    bl_idname = "opencue.reset_to_scene"
    bl_label = "Reset to Scene"
    bl_description = "Reset frame range to match current scene settings"
    
    def execute(self, context):
        scene = context.scene
        props = scene.opencue_props
        
        props.frame_start = scene.frame_start
        props.frame_end = scene.frame_end
        
        self.report({'INFO'}, f"Reset to scene range: {props.frame_start}-{props.frame_end}")
        return {'FINISHED'}


# ============================================================================
# UI Panels
# ============================================================================

class OPENCUE_PT_main_panel(Panel):
    """Main OpenCue submission panel"""
    bl_label = "OpenCue Submit"
    bl_idname = "OPENCUE_PT_main_panel"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'OpenCue'
    
    def draw(self, context):
        layout = self.layout
        scene = context.scene
        props = scene.opencue_props
        
        # Job Information
        box = layout.box()
        box.label(text="Job Information:", icon='RENDER_ANIMATION')
        box.prop(props, "job_name")
        box.prop(props, "show")
        box.prop(props, "shot")
        
        # Frame Range
        box = layout.box()
        box.label(text="Frame Range:", icon='PREVIEW_RANGE')
        row = box.row(align=True)
        row.prop(props, "frame_start")
        row.prop(props, "frame_end")
        row = box.row()
        row.operator("opencue.reset_to_scene", icon='FILE_REFRESH')
        
        # Render Settings
        box = layout.box()
        box.label(text="Render Settings:", icon='SETTINGS')
        box.prop(props, "chunk_size")
        box.prop(props, "use_compositing")
        
        # Resource Allocation
        box = layout.box()
        box.label(text="Resource Allocation:", icon='SYSTEM')
        box.prop(props, "cores")
        box.prop(props, "memory")
        box.prop(props, "max_cores")
        
        # Submit Button
        layout.separator()
        row = layout.row()
        row.scale_y = 2.0
        row.operator("opencue.submit_job", icon='RENDER_ANIMATION')
        
        # Info
        layout.separator()
        box = layout.box()
        box.label(text="Current Scene:", icon='INFO')
        if bpy.data.filepath:
            box.label(text=f"File: {os.path.basename(bpy.data.filepath)}")
            box.label(text=f"Scene: {scene.name}")
        else:
            box.label(text="File: Not saved", icon='ERROR')


# ============================================================================
# Registration
# ============================================================================

classes = (
    OpenCueJobProperties,
    OpenCueAddonPreferences,
    OPENCUE_OT_submit_job,
    OPENCUE_OT_reset_to_scene,
    OPENCUE_PT_main_panel,
)


def register():
    """Register add-on classes and properties"""
    for cls in classes:
        bpy.utils.register_class(cls)
    
    # Add properties to scene
    bpy.types.Scene.opencue_props = PointerProperty(type=OpenCueJobProperties)
    
    print("OpenCue Submit add-on registered")


def unregister():
    """Unregister add-on classes and properties"""
    # Remove properties from scene
    del bpy.types.Scene.opencue_props
    
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
    
    print("OpenCue Submit add-on unregistered")


if __name__ == "__main__":
    register()
