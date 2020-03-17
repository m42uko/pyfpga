#
# Copyright (C) 2019-2020 INTI
# Copyright (C) 2019-2020 Rodrigo A. Melo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

"""fpga.tool.libero

Implements the support of Libero (Microchip/Microsemi).
"""

import re

from fpga.tool import Tool

_TEMPLATES = {
    'fpga': """\
""",
    'detect': """\
"""
}

# open_project -file {$TEMPDIR/libero.prjx}
# run_tool -name {CONFIGURE_CHAIN} -script {$TEMPDIR/flashpro.tcl}
# run_tool -name {PROGRAMDEVICE}

# set flashpro_programmer "configure_flashpro5_prg -vpump {ON} \
# -clk_mode {free_running_clk} -programming_method {spi_slave} \
# -force_freq {OFF} -freq {4000000}"


class Libero(Tool):
    """Implementation of the class to support Libero."""

    _TOOL = 'libero'
    _EXTENSION = 'prjx'
    _PART = 'mpf100t-1-fcg484'

    _GEN_COMMAND = 'libero SCRIPT:libero.tcl'
    _TRF_COMMAND = ''

    _DEVTYPES = ['fpga']

    _GENERATED = [
        'libero.tcl'
    ]

    def set_part(self, part):
        try:
            family, speed, package = re.findall(r'(\w+)-(\w+)-*(\w*)', part)[0]
            if len(speed) > len(package):
                speed, package = package, speed
            if speed == '':
                speed = 'STD'
            part = "{}-{}-{}".format(family, speed, package)
        except IndexError:
            raise ValueError(
                'Part must be FAMILY-SPEED-PACKAGE or FAMILY-PACKAGE'
            )
        self.part = part

    def transfer(self, devtype, position, part, width, capture):
        super().transfer(devtype, position, part, width, capture)
        raise NotImplementedError('transfer(libero)')
