#
# Copyright (C) 2020-2024 Rodrigo A. Melo
#
# SPDX-License-Identifier: GPL-3.0-or-later
#

"""
Implements support for an Open Source development flow.
"""

# pylint: disable=too-many-locals
# pylint: disable=too-many-branches
# pylint: disable=duplicate-code

from pathlib import Path
from pyfpga.project import Project


class Openflow(Project):
    """Class to support Open Source tools."""

    def _make_prepare(self, steps):
        info = get_info(self.data.get('part', 'hx8k-ct256'))
        context = {
            'PROJECT': self.name or 'openflow',
            'FAMILY': info['family'],
            'DEVICE': info['device'],
            'PACKAGE': info['package']
        }
        for step in steps:
            context[step] = 1
        if 'includes' in self.data:
            includes = []
            for include in self.data['includes']:
                includes.append(f'-I{str(include)}')
            context['INCLUDES'] = ' '.join(includes)
        files = []
        if 'files' in self.data:
            for file in self.data['files']:
                files.append(f'read_verilog -defer {file}')
        if files:
            context['VLOGS'] = '\n'.join(files)
#            for file in self.data['files']:
#                if 'lib' in self.data['files'][file]:
#                    lib = self.data['files'][file]['lib']
#                    files.append(
#                        f'set_property library {lib} [get_files {file}]'
#                    )
        if 'constraints' in self.data:
            constraints = []
            for constraint in self.data['constraints']:
                constraints.append(str(constraint))
            context['CONSTRAINTS'] = ' '.join(constraints)
        if 'top' in self.data:
            context['TOP'] = self.data['top']
        if 'defines' in self.data:
            defines = []
            for key, value in self.data['defines'].items():
                defines.append(f'-D{key}={value}')
            context['DEFINES'] = ' '.join(defines)
        if 'params' in self.data:
            params = []
            for key, value in self.data['params'].items():
                params.append(f'-set {key} {value}')
            context['PARAMS'] = ' '.join(params)
        if 'hooks' in self.data:
            for stage in self.data['hooks']:
                context[stage.upper()] = '\n'.join(self.data['hooks'][stage])
        self._create_file('openflow', 'sh', context)
        return 'bash openflow.sh'

    def _prog_prepare(self, bitstream, position):
        _ = position
        if not bitstream:
            basename = self.name or 'openflow'
            bitstream = Path(self.odir).resolve() / f'{basename}.bit'
        context = {'BITSTREAM': bitstream}
        self._create_file('openflow-prog', 'sh', context)
        return 'bash openflow-prog.sh'

#     def _create_gen_script(self, tasks):
#         # Files
#         constraints = []
#         verilogs = []
#         vhdls = []
#         for file in self.files['vhdl']:
#             lib = ''
#             if file[1] is not None:
#                 lib = f'--work={file[1]}'
#             vhdls.append(f'{self.tools["ghdl"]} -a $FLAGS {lib} {file[0]}')
#         for file in self.files['verilog']:
#             if file[0].endswith('.sv'):
#                 verilogs.append(f'read_verilog -sv -defer {file[0]}')
#             else:
#                 verilogs.append(f'read_verilog -defer {file[0]}')
#         for file in self.files['constraint']:
#             constraints.append(file[0])
#         if len(vhdls) > 0:
#             verilogs = [f'ghdl $FLAGS {self.top}']


def get_info(part):
    """Get info about the FPGA part.

    :param part: the FPGA part as specified by the tool
    :returns: a dictionary with the keys family, device and package
    """
    part = part.lower()
    # Looking for the family
    family = None
    families = [
        # From <YOSYS>/techlibs/xilinx/synth_xilinx.cc
        'xcup', 'xcu', 'xc7', 'xc6s', 'xc6v', 'xc5v', 'xc4v', 'xc3sda',
        'xc3sa', 'xc3se', 'xc3s', 'xc2vp', 'xc2v', 'xcve', 'xcv'
    ]
    for item in families:
        if part.startswith(item):
            family = item
            break
    families = [
        # From <nextpnr>/ice40/main.cc
        'lp384', 'lp1k', 'lp4k', 'lp8k', 'hx1k', 'hx4k', 'hx8k',
        'up3k', 'up5k', 'u1k', 'u2k', 'u4k'
    ]
    if part.startswith(tuple(families)):
        family = 'ice40'
    families = [
        # From <nextpnr>/ecp5/main.cc
        '12k', '25k', '45k', '85k', 'um-25k', 'um-45k', 'um-85k',
        'um5g-25k', 'um5g-45k', 'um5g-85k'
    ]
    if part.startswith(tuple(families)):
        family = 'ecp5'
    # Looking for the device and package
    device = None
    package = None
    aux = part.split('-')
    if len(aux) == 2:
        device = aux[0]
        package = aux[1]
    elif len(aux) == 3:
        device = f'{aux[0]}-{aux[1]}'
        package = aux[2]
    else:
        raise ValueError('Part must be DEVICE-PACKAGE')
    if family in ['lp4k', 'hx4k']:  # See http://www.clifford.at/icestorm
        device = device.replace('4', '8')
        package += ":4k"
    if family == 'ecp5':
        package = package.upper()
    # Finish
    return {'family': family, 'device': device, 'package': package}
