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


"""Code for constructing a job submission and sending it to the Cuebot."""


from __future__ import print_function
from __future__ import division
from __future__ import absolute_import

from builtins import str
import re
import shlex

import outline
import outline.cuerun
import outline.modules.shell

from cuesubmit import Constants
from cuesubmit import JobTypes
from cuesubmit import Util


def isSoloFlag(flag):
    """ Check if the flag is solo, meaning it has no associated value
     solo flags are marked with a ~ (ex: --background~)
     """
    return re.match(r"^-+\w+~$", flag)


def isFlag(flag):
    """ Check if the provided string is a flag (starts with a -)"""
    return re.match(r"^-+\w+$", flag)


def formatValue(flag, value, isPath, isMandatory):
    """ Adds quotes around file/folder path variables
     and provide an error value to display for missing mandatory values.
    """
    if isPath and value:
        value = f'"{value}"'
    if isMandatory and value in ('', None):
        value = f'!!missing value for {flag}!!'
    return value


def buildDynamicCmd(layerData):
    """From a layer, builds a customized render command."""
    renderCommand = Constants.RENDER_CMDS[layerData.layerType].get('command')
    for (flag, isPath, isMandatory), value in layerData.cmd.items():
        if isSoloFlag(flag):
            renderCommand += f' {flag[:-1]}'
            continue
        value = formatValue(flag, value, isPath, isMandatory)
        if isFlag(flag) and value not in ('', None):
            # flag and value
            renderCommand += f' {flag} {value}'
            continue
        # solo argument without flag
        if value not in ('', None):
            renderCommand += f' {value}'

    return renderCommand


def buildMayaCmd(layerData, silent=False):
    """From a layer, builds a Maya Render command as a list.
    
    Returns a list to properly preserve paths with spaces and special characters.
    """
    camera = layerData.cmd.get('camera')
    mayaFile = layerData.cmd.get('mayaFile')
    if not mayaFile and not silent:
        raise ValueError('No Maya File provided. Cannot submit job.')
    
    args = [Constants.MAYA_RENDER_CMD, '-r', 'file', '-s', Constants.FRAME_START_TOKEN,
            '-e', Constants.FRAME_END_TOKEN]
    if camera:
        args.extend(['-cam', camera])
    args.append(mayaFile)
    return args


def buildNukeCmd(layerData, silent=False):
    """From a layer, builds a Nuke Render command as a list.
    
    Returns a list to properly preserve paths with spaces and special characters.
    """
    writeNodes = layerData.cmd.get('writeNodes')
    nukeFile = layerData.cmd.get('nukeFile')
    if not nukeFile and not silent:
        raise ValueError('No Nuke file provided. Cannot submit job.')
    
    args = [Constants.NUKE_RENDER_CMD, '-F', Constants.FRAME_TOKEN]
    if writeNodes:
        args.extend(['-X', writeNodes])
    args.extend(['-x', nukeFile])
    return args


def buildBlenderCmd(layerData, silent=False):
    """From a layer, builds a Blender render command as a list.

    Returns a list to properly preserve paths with spaces and special characters.
    """
    blenderFile = layerData.cmd.get('blenderFile')
    blenderExecutable = layerData.cmd.get('blenderExecutable', Constants.BLENDER_RENDER_CMD)
    outputPath = layerData.cmd.get('outputPath')
    outputFormat = layerData.cmd.get('outputFormat')
    useCompositing = layerData.cmd.get('useCompositing', True)
    frameRange = layerData.layerRange
    if not blenderFile and not silent:
        raise ValueError('No Blender file provided. Cannot submit job.')

    args = [blenderExecutable, '-b', '-noaudio', blenderFile]
    if useCompositing:
        args.append('--use-compositing')
    if outputPath:
        args.extend(['-o', outputPath])
    if outputFormat:
        args.extend(['-F', outputFormat])
    if re.match(r"^\d+-\d+$", frameRange):
        args.extend(['-s', Constants.FRAME_START_TOKEN, '-e', Constants.FRAME_END_TOKEN, '-a'])
    else:
        args.extend(['-f', Constants.FRAME_TOKEN])
    return args


def buildLayer(layerData, command, lastLayer=None):
    """Creates a PyOutline Layer for the given layerData.

    @type layerData: ui.Layer.LayerData
    @param layerData: layer data from the ui
    @type command: str or list
    @param command: command to run (string or list of arguments)
    @type lastLayer: outline.layer.Layer
    @param lastLayer: layer that this new layer should be dependent on if dependType is set.
    """
    threadable = False
    if layerData.overrideCores:
        threadable = float(layerData.cores) >= 2 or float(layerData.cores) <= 0
    elif layerData.services and layerData.services[0] in Util.getServices():
        threadable = Util.getServiceOption(layerData.services[0], 'threadable')

    cores = layerData.cores if layerData.overrideCores else None
    command_tokens = command if isinstance(command, list) else shlex.split(command)
    layer = outline.modules.shell.Shell(
        layerData.name, command=command_tokens, chunk=layerData.chunk,
        cores=cores,
        range=str(layerData.layerRange), threadable=threadable)
    if layerData.services:
        layer.set_service(layerData.services[0])
    if layerData.limits:
        layer.set_limits(layerData.limits)
    if layerData.dependType and lastLayer:
        if layerData.dependType == 'Layer':
            layer.depend_all(lastLayer)
        else:
            layer.depend_on(lastLayer)
    return layer


def buildLayerCommand(layerData, silent=False):
    """Builds the command to be sent per jobType (str or list)."""
    if layerData.layerType in JobTypes.JobTypes.FROM_CONFIG_FILE:
        return buildDynamicCmd(layerData)
    if layerData.layerType == JobTypes.JobTypes.MAYA:
        return buildMayaCmd(layerData, silent)
    if layerData.layerType == JobTypes.JobTypes.SHELL:
        # Shell commands are user-provided strings that may already have quotes
        # Return as list for consistent handling
        shell_cmd = layerData.cmd.get('commandTextBox') if silent else layerData.cmd['commandTextBox']
        return shlex.split(shell_cmd) if shell_cmd else []
    if layerData.layerType == JobTypes.JobTypes.NUKE:
        return buildNukeCmd(layerData, silent)
    if layerData.layerType == JobTypes.JobTypes.BLENDER:
        return buildBlenderCmd(layerData, silent)
    if silent:
        return 'Error: unrecognized layer type {}'.format(layerData.layerType)
    raise ValueError('unrecognized layer type {}'.format(layerData.layerType))


def submitJob(jobData):
    """Submits the job using the PyOutline API."""
    ol = outline.Outline(
        jobData['name'], shot=jobData['shot'], show=jobData['show'], user=jobData['username'])
    lastLayer = None
    for layerData in jobData['layers']:
        command = buildLayerCommand(layerData)
        layer = buildLayer(layerData, command, lastLayer)
        ol.add_layer(layer)
        lastLayer = layer

    if 'facility' in jobData:
        ol.set_facility(jobData['facility'])

    return outline.cuerun.launch(ol, use_pycuerun=False)
