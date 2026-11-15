from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / ".tools"))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
files=sorted(Path("CrateShop").glob("*.lua"))
for path in files:
    lua.execute("assert(loadfile(...))", str(path))
toc=Path("CrateShop/CrateShop.toc").read_text(encoding="utf-8")
entries=[line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
assert len(entries)==len(files)
for entry in entries:
    assert (Path("CrateShop")/entry).is_file(),entry
for path in [*Path("CrateShop").glob("*"),*Path("tests").glob("*"),*Path("docs").rglob("*"),Path("README.md"),Path(".gitignore")]:
    if path.is_file():
        content=path.read_text(encoding="utf-8")
        assert not content.startswith("\ufeff"),path
        assert all(line==line.rstrip() for line in content.splitlines()),path
print(f"Syntax Lua 5.1: {len(files)} modules; TOC references and text whitespace OK")
