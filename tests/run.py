"""Optional development runner; addon requires neither Python nor Lupa."""
import os
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / ".tools"))
from lupa.lua51 import LuaRuntime

os.chdir(root)
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute("dofile('tests/run.lua')")