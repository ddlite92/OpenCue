# OpenCue Blender Add-on

A Blender add-on for submitting render jobs directly to an OpenCue render farm from within Blender's UI.

## Features

- **Native Blender Integration**: Submit jobs directly from Blender's 3D Viewport sidebar
- **Flexible Configuration**: Configurable frame ranges, chunk sizes, and resource allocation
- **Resource Management**: Control CPU cores and memory per task
- **Scene-based Rendering**: Automatically detects current scene and file
- **Compositing Support**: Optional compositor node rendering

## Requirements

- Blender 3.0 or higher
- Python environment with OpenCue libraries installed:
  - `pycue`
  - `pyoutline`
  - `outline`
- Access to an OpenCue render farm
- OpenCue RQD (render queue daemon) running on render nodes

## Installation

### 1. Install the Add-on

1. Open Blender
2. Navigate to **Edit > Preferences > Add-ons**
3. Click **Install** button
4. Browse to and select the `__init__.py` file from this directory
5. Enable the add-on by checking the box next to **Render: OpenCue Submit**

### 2. Configure Preferences

1. In the Add-ons preferences, expand the **OpenCue Submit** add-on
2. Configure the following paths:

   - **Python Executable**: Path to Python with OpenCue libraries installed
     - Example: `C:\Users\YourUser\venv\Scripts\python.exe`
   
   - **Wrapper Script**: Path to `blender_wrapper.py`
     - Example: `C:\Path\To\OpenCue\cuesubmit\plugins\blender\blender_wrapper.py`
   
   - **Submission Script**: Path to `submit_job.py`
     - Example: `C:\Path\To\OpenCue\cuesubmit\plugins\blender\submit_job.py`

3. Set default values:
   - **Default Show**: Your default show/project name
   - **Default Cores**: Default CPU cores per task (e.g., 4)
   - **Default Memory**: Default memory in MB (e.g., 4096)

4. Click **Save Preferences**

## Usage

### Basic Workflow

1. **Open your Blender scene**
   - Ensure your scene is saved (File > Save)
   - Set up your render settings, camera, and output path

2. **Open the OpenCue panel**
   - In the 3D Viewport, press `N` to show the sidebar
   - Click on the **OpenCue** tab

3. **Configure job settings**
   - **Job Name**: Name for your render job (timestamp will be added automatically)
   - **Show**: Project/show name for organization
   - **Shot**: Shot identifier
   - **Frame Range**: Start and end frames to render
     - Click **Reset to Scene** to match your scene's frame range
   - **Chunk Size**: Number of frames per render task
     - 1 = Each frame is a separate task
     - 10 = Frames rendered in groups of 10
   - **Use Compositing**: Enable if your scene uses compositor nodes
   - **Cores**: CPU cores allocated per task
   - **Memory**: RAM allocated per task (in MB)
   - **Max Cores (Job)**: Maximum cores for entire job (0 = unlimited)

4. **Submit the job**
   - Click the **Submit to OpenCue** button
   - Check the Blender console for submission status
   - Monitor job progress in OpenCue GUI (cuegui)

### Example Configuration

For a typical render job:
```
Job Name: my_animation
Show: my_project
Shot: shot_010
Frame Range: 1 - 100
Chunk Size: 5
Cores: 8
Memory: 8192 MB
Max Cores: 32
```

This will create 20 tasks (100 frames ÷ 5 frames per chunk), each using 8 cores and 8GB RAM, with a maximum of 32 cores running simultaneously across all tasks.

## Troubleshooting

### "Please save your Blender file before submitting"
- Save your `.blend` file before attempting to submit

### "Python executable not found"
- Verify the Python executable path in add-on preferences
- Ensure the Python environment has OpenCue libraries installed

### "Submission script not found"
- Verify the paths to `blender_wrapper.py` and `submit_job.py` in preferences
- Ensure the files exist at the specified locations

### "Submission failed" or timeout errors
- Check that OpenCue services are running (Cuebot)
- Verify network connectivity to OpenCue farm
- Check Python environment has all required packages
- Review Blender console output for detailed error messages

### Job submitted but frames not rendering
- Verify RQD is running on render nodes
- Check that render nodes have access to the `.blend` file path
- Ensure Blender is installed on render nodes at expected path
- Review job logs in OpenCue GUI

## Architecture

### Components

1. **`__init__.py`**: Main Blender add-on file
   - Registers UI panels, operators, and properties
   - Handles user interaction within Blender
   - Calls submission script with job parameters

2. **`submit_job.py`**: Job submission script
   - Creates OpenCue job using pyoutline
   - Configures layers, frame ranges, and resources
   - Submits job to OpenCue farm

3. **`blender_wrapper.py`**: Render node wrapper
   - Executed on each render node for each task
   - Receives frame range from OpenCue environment variables
   - Launches Blender in background mode to render frames

### Workflow

```
Blender UI (User)
    ↓
__init__.py (Submit Operator)
    ↓
submit_job.py (Creates OpenCue Job)
    ↓
OpenCue Farm (Cuebot)
    ↓
Render Nodes (RQD)
    ↓
blender_wrapper.py (Renders Frames)
    ↓
Blender (Background Rendering)
```

## Advanced Configuration

### Custom Blender Executable

If Blender is installed in a non-standard location on render nodes, you can modify `submit_job.py` to specify the path:

```python
# In submit_job.py, modify the blender_exe detection logic
blender_exe = r"C:\Custom\Path\To\blender.exe"
```

### Environment Variables

The wrapper script uses OpenCue environment variables:
- `CUE_IFRAME`: Start frame of the current chunk
- `CUE_CHUNK`: Number of frames in the chunk

### Resource Limits

- **Cores per Task**: Controls CPU allocation for each render task
- **Memory per Task**: Controls RAM allocation for each task
- **Max Cores (Job)**: Limits total concurrent cores across all tasks
  - Set to 0 for unlimited
  - Useful for controlling farm resource usage

## Support

For issues, questions, or contributions:
- OpenCue GitHub: https://github.com/AcademySoftwareFoundation/OpenCue
- OpenCue Documentation: https://www.opencue.io/docs/

## License

This add-on is part of the OpenCue project and is licensed under the Apache License 2.0.
See the LICENSE file in the OpenCue repository for details.
