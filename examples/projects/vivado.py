"""Vivado examples."""

import argparse

from pyfpga.vivado import Vivado


parser = argparse.ArgumentParser()
parser.add_argument(
    '--board', choices=['zybo', 'arty'], default='zybo'
)
parser.add_argument(
    '--source', choices=['vlog', 'vhdl', 'slog'], default='vlog'
)
parser.add_argument(
    '--action', choices=['make', 'prog', 'all'], default='make'
)
args = parser.parse_args()

prj = Vivado(odir='../build/vivado')

if args.board == 'zybo':
    prj.set_part('xc7z010-1-clg400')
    prj.add_param('FREQ', '125000000')
    prj.add_cons('../sources/zybo/ZYBO/timing.xdc', 'syn')
    prj.add_cons('../sources/zybo/ZYBO/clk.xdc', 'par')
    prj.add_cons('../sources/zybo/ZYBO/led.xdc', 'par')
if args.board == 'arty':
    prj.set_part('xc7a35ticsg324-1L')
    prj.add_param('FREQ', '100000000')
    prj.add_cons('../sources/arty/a7-35t/timing.xdc', 'syn')
    prj.add_cons('../sources/arty/a7-35t/clk.xdc', 'par')
    prj.add_cons('../sources/arty/a7-35t/led.xdc', 'par')
prj.add_param('SECS', '1')

if args.source == 'vhdl':
    prj.add_vhdl('../sources/vhdl/*.vhdl', 'blink_lib')
if args.source == 'vlog':
    prj.add_include('../sources/vlog/include1')
    prj.add_include('../sources/vlog/include2')
    prj.add_vlog('../sources/vlog/*.v')
if args.source == 'slog':
    prj.add_include('../sources/slog/include1')
    prj.add_include('../sources/slog/include2')
    prj.add_vlog('../sources/slog/*.sv')
if args.source in ['vlog', 'slog']:
    prj.add_define('DEFINE1', '1')
    prj.add_define('DEFINE2', '1')

prj.set_top('Top')

if args.action in ['make', 'all']:
    prj.make()

if args.action in ['prog', 'all']:
    prj.prog()