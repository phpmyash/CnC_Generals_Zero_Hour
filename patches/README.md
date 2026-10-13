# Patches for a modern-Windows Zero Hour build

The EA source drop in this repository is a preservation release. It targets
Visual C++ 6 and expects a dozen proprietary SDKs that were stripped before
publication, so it does not compile on its own.

The practical way to get a patched executable for a Steam or EA App copy of
the game is to build on top of
[TheSuperHackers/GeneralsGameCode](https://github.com/TheSuperHackers/GeneralsGameCode).
That project is the same source with a CMake build, Visual Studio 2022 and
MinGW support, replacement dependencies, and several thousand bug fixes. It
already contains fixes for the items found in the first pass over this
repository, among them:

- 64-bit physical memory detection (the original code wraps negative on any
  machine with 2GB or more of RAM and forces the lowest detail preset).
- A frame pacer that sleeps instead of spinning on `Sleep(0)`, so the main
  thread no longer pins a core while waiting for the next frame.
- The fullscreen crash on Windows 10 and 11, among many other crash fixes.

The patches in this directory are applied on top of that project by
`scripts/build-zh-patched.sh`:

| Patch | What it does |
| --- | --- |
| `0001-link-large-address-aware.patch` | Links the game executable with the large-address-aware flag so 64-bit Windows gives the 32-bit process 4GB of address space instead of 2GB. |
| `0002-stringex-sse2-guard.patch` | Fixes a build break in the MinGW cross build: the SSE2 string helper was selected on every 32-bit MinGW target, including ones compiled without SSE2. |
| `0003-mingw-enable-sse2.patch` | Compiles the MinGW build with SSE2 enabled, matching the Visual Studio 2022 x86 default. Scalar floating point stays on x87. |
| `0004-mingw-link-order.patch` | Fixes the final link in the MinGW cross build: the engine and device libraries reference each other, so they are linked as a rescanned group, and the Winsock import library is added for the FTP code. |

## Building

```sh
sudo apt-get install g++-mingw-w64-i686 cmake make git wine64-tools libwine-dev
scripts/build-zh-patched.sh
```

The result is `build/zh-patched/generalszh.exe`.

## Installing into the Steam copy

1. Open the game folder, normally
   `C:\Program Files (x86)\Steam\steamapps\common\Command and Conquer Generals - Zero Hour`
   (right-click the game in Steam, Manage, Browse local files).
2. Copy `generalszh.exe` next to the existing `generals.exe`. Do not delete or
   rename the original.
3. Launch `generalszh.exe` directly, or add it to Steam as a non-Steam game.
   The game data, your options and your saves are all read from the same
   places the original executable uses.

To go back, launch `generals.exe` again or delete `generalszh.exe`.

## What this build does and does not change

- **Memory.** Up to 4GB of address space instead of 2GB. A true "use all my
  RAM" build needs a 64-bit port, which is still a work in progress in forks
  such as GeneralsX; the Miles audio and Bink video SDKs have no 64-bit
  versions and must be replaced first.
- **Cores.** The simulation is deterministic lockstep and runs on one thread
  by design; multiplayer and replays depend on that. This build removes the
  busy-wait that pinned a core, and the MinGW/VS2022 optimizer produces much
  faster single-thread code than Visual C++ 6, but it does not spread the
  simulation across cores.
- **Multiplayer.** A MinGW-compiled executable is not guaranteed to stay in
  sync with players running the retail or VC6-built executable, because
  floating-point code generation differs. Use it for single player and
  skirmish, or have every player run the same build.
