#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# catsdk 1.0 toolkit · FILES = OFF
# SDK catalogs live IN THIS FILE ONLY — no manifest/config sidecars.
# autoinstall wget-builds toolchains into CATSDK_PREFIX (default ~/.catsdk).
# ═══════════════════════════════════════════════════════════════════

# sh / bash --posix: re-exec full bash (arrays, [[ ]], etc.)
if [ -z "${BASH_VERSION:-}" ] || [ "${POSIXLY_CORRECT:-}" = "y" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail

CATSDK_VERSION="1.0"
CATSDK_NAME="catsdk"
CATSDK_TAG="files = off"
FILES="off"
CATSDK_FILE="${BASH_SOURCE[0]:-catsdk.sh}"
CATSDK_PREFIX="${CATSDK_PREFIX:-${HOME}/.catsdk}"
CATSDK_SRC="${CATSDK_SRC:-${CATSDK_PREFIX}/src}"
CATSDK_ROOT="${CATSDK_ROOT:-${CATSDK_PREFIX}/root}"

# Re-expand after re-exec under bash
CATSDK_PREFIX="${CATSDK_PREFIX/#\~/$HOME}"
CATSDK_SRC="${CATSDK_SRC/#\~/$HOME}"
CATSDK_ROOT="${CATSDK_ROOT/#\~/$HOME}"

_catsdk_normalize_paths() {
  # Legacy: CATSDK_ROOT=$HOME/catsdk (missing /root)
  if [[ "${CATSDK_ROOT}" == "${HOME}/catsdk" ]] || [[ "${CATSDK_ROOT}" == "${CATSDK_PREFIX}" && "${CATSDK_ROOT}" != *"/root" ]]; then
    CATSDK_PREFIX="${HOME}/.catsdk"
    CATSDK_SRC="${CATSDK_PREFIX}/src"
    CATSDK_ROOT="${CATSDK_PREFIX}/root"
  fi
  if [[ "${CATSDK_PREFIX}" == "${HOME}/catsdk" && ! -d "${HOME}/catsdk/root" ]]; then
    CATSDK_PREFIX="${HOME}/.catsdk"
    CATSDK_SRC="${CATSDK_PREFIX}/src"
    CATSDK_ROOT="${CATSDK_PREFIX}/root"
  fi
}
_catsdk_normalize_paths

# Embedded mirror table (in this file only — not fetched from anywhere)
_embedded_mirrors() {
  cat <<'M'
gcc|14.2.0|https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz
gcc|13.3.0|https://ftp.gnu.org/gnu/gcc/gcc-13.3.0/gcc-13.3.0.tar.xz
gcc|12.4.0|https://ftp.gnu.org/gnu/gcc/gcc-12.4.0/gcc-12.4.0.tar.xz
gcc|12.4.0|https://ftpmirror.gnu.org/gnu/gcc/gcc-12.4.0/gcc-12.4.0.tar.xz
gcc|12.4.0|https://mirrors.kernel.org/gnu/gcc/gcc-12.4.0/gcc-12.4.0.tar.xz
gcc|11.5.0|https://ftp.gnu.org/gnu/gcc/gcc-11.5.0/gcc-11.5.0.tar.xz
dasm|2.20.14|https://sources.voidlinux.org/dasm-2.20.14.1/2.20.14.1.tar.gz
dasm|2.20.14|https://deb.debian.org/debian/pool/main/d/dasm/dasm_2.20.15~20201109+really2.20.14.1.orig.tar.gz
dasm|2.20.14|https://downloads.sourceforge.net/project/dasm/dasm/2.20.14/dasm-2.20.14.tar.gz
dasm|2.20.14|https://downloads.sourceforge.net/project/dasm/dasm/2.20.14/dasm-2.20.14-src.tar.gz
dasm|2.20.14|https://netcologne.dl.sourceforge.net/project/dasm/dasm/2.20.14/dasm-2.20.14-src.tar.gz
cc65|2.19|https://downloads.sourceforge.net/project/cc65/cc65/cc65-2.19.tar.bz2
cc65|2.18|https://downloads.sourceforge.net/project/cc65/cc65/cc65-2.18.tar.bz2
binutils|2.43|https://ftp.gnu.org/gnu/binutils/binutils-2.43.tar.xz
binutils|2.46.1|https://ftp.gnu.org/gnu/binutils/binutils-2.46.1.tar.xz
binutils|2.46.1|https://ftpmirror.gnu.org/gnu/binutils/binutils-2.46.1.tar.xz
M
}

_cyan()  { printf '\033[36m%s\033[0m\n' "$*" >&2; }
_green() { printf '\033[32m%s\033[0m\n' "$*" >&2; }
_yellow(){ printf '\033[33m%s\033[0m\n' "$*" >&2; }
_red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
_bold()  { printf '\033[1m%s\033[0m\n' "$*" >&2; }

ascii_banner() {
  cat <<'ASCII'
   ____      _   ____  ____  _  __   ___   ____
  / ___| __ _| |_|  _ \/ ___|| |/ /  / _ \ |  _ \
 | |    / _` | __| | | \___ \| ' /  | | | || | | |
 | |___| (_| | |_| |_| |___) | . \  | |_| || |_| |
  \____|\__,_|\__|____/|____/|_|\_\  \___/ |____/

        catsdk 1.0 toolkit
   IN THIS FILE · FILES = OFF
   run = autoinstall everything
   gcc 1930-2026 · Atari ──────► PS5
ASCII
  _cyan "  ${CATSDK_TAG} · all data inside ${CATSDK_FILE##*/}"
}

banner() {
  ascii_banner
}

usage() {
  banner
  cat <<'EOF'

Usage (zero args = autoinstall everything · FILES = OFF):
  catsdk.sh                 Install all programs + platforms → ~/.catsdk
  catsdk.sh <command>       list · doctor · env · sample · etc.

Commands:
  list [filter]           All compilers (1930–2026) + Atari→PS5 toolchains
  list-gcc [year]         GCC releases 1930–2026 only
  list-chain              Every compiler on Atari→PS5 path
  list-asm                6502/68000 ASM tools (cc65 · dasm · ca65 · ld65…)
  platforms               Platform install targets
  search <term>           Search catalog
  install <platform>      Show embedded pack OR autoinstall if --apply
  install-all             All embedded packs (add --apply to wget+build)
  autoinstall [platform]  Wget+install one target (or all if omitted)
  autoinstall-all         Same as zero-arg — install everything
  programs|progs          Core program bundle only (faster)
  import [playstation]    PS2→PS5 dirs + cross-GCC + Sony SDK wiring
  wget-gcc <ver>          Embedded GCC URL from this file
  mirrors                 Embedded wget URL table (in this file)
  mirrors test [pkg] [ver] Probe each mirror URL (no install)
  this-file               Prove FILES=OFF — list embedded sections
  doctor                  Host probes + embedded entry counts
  env                     In-memory exports (stdout only)
  sample <platform>       Hello source embedded in this file
  version                 catsdk 1.0

Atari → PS5 platforms (install-all):
  atari2600 atari5200 atari7800 atari8 atarist atarilynx atarijaguar atarifalcon
  ps2 ps3 ps4 ps5
  gcc clang cc65 dasm binutils asm

ASM autoinstall targets:
  cc65 dasm asm (all asm) · atari2600 atari8 atarijaguar

Examples:
  ./catsdk.sh autoinstall cc65
  ./catsdk.sh autoinstall dasm
  ./catsdk.sh autoinstall asm
  ./catsdk.sh autoinstall atari2600
  ./catsdk.sh autoinstall atari8
  ./catsdk.sh import playstation
  ./catsdk.sh list-asm

Notes:
  · FILES = OFF — catalogs/samples/URLs live only in catsdk.sh (no manifest files).
  · Zero-arg run installs everything → ~/.catsdk (catalog stays in this file).
  · Faster run: catsdk.sh programs (core tools only).
  · After run: eval "$(catsdk.sh env --prefix)" — then binutils gas gasm work from ~/.catsdk/root/bin
  · Do not export CC=cc65 globally; use only for 6502 builds (breaks cross-GCC configure)
  · PS4/PS5 need Sony DevNet SDK paths (orbis-clang / prospero-clang).
  · PS2/PS3: built from source on zero-arg run (or: autoinstall ps2).
  · binutils = commands as + ld (there is no binutils binary).
  · gas = use as · GASM = historical Jaguar tool (catalog only).
  · ld65 not lda65 · cc65/ca65/ld65 “no input” with no args = installed OK.
EOF
}

# ── EMBEDDED SAMPLES (files = off · never written to disk unless you redirect) ──
_embedded_sample() {
  local plat="${1:-gcc}"
  case "$plat" in
    atari2600|atari8|atari5200|atari7800|atarilynx)
      cat <<'S'
; catsdk 1.0 · Atari 6502 hello · files = off
        .segment "CODE"
main:   lda #'H'
        jsr $FFD2          ; ROM print
        rts
S
      ;;
    atarist|atarijaguar|atarifalcon)
      cat <<'S'
/* catsdk 1.0 · Atari ST 68000 hello · files = off */
#include <stdio.h>
int main(void) {
    printf("catsdk 1.0 · Atari ST\n");
    return 0;
}
S
      ;;
    ps1|ps2)
      cat <<'S'
/* catsdk 1.0 · PSX MIPS hello · files = off */
#include <stdio.h>
int main(void) {
    printf("catsdk 1.0 · PlayStation\n");
    return 0;
}
S
      ;;
    ps3)
      cat <<'S'
/* catsdk 1.0 · PS3 Cell hello · files = off */
#include <stdio.h>
int main(void) {
    printf("catsdk 1.0 · PS3\n");
    return 0;
}
S
      ;;
    ps4)
      cat <<'S'
// catsdk 1.0 · PS4 Orbis hello · files = off
// Build with: orbis-clang hello.c -o hello.elf
#include <stdio.h>
int main(void) {
    printf("catsdk 1.0 · PS4\n");
    return 0;
}
S
      ;;
    ps5)
      cat <<'S'
// catsdk 1.0 · PS5 Prospero hello · files = off
// Build with: prospero-clang hello.c -o hello.elf
#include <stdio.h>
int main(void) {
    printf("catsdk 1.0 · PS5\n");
    return 0;
}
S
      ;;
    gcc|host|*)
      cat <<'S'
/* catsdk 1.0 · host GCC hello · files = off */
#include <stdio.h>
int main(void) {
    printf("catsdk 1.0 toolkit · files = off\n");
    return 0;
}
S
      ;;
  esac
}

cmd_sample() {
  local plat="${1:-gcc}"
  banner
  _bold "Embedded sample · ${plat} · ${CATSDK_TAG}"
  echo ""
  _embedded_sample "$plat"
}

# ── ATARI → PS5: every compiler (embedded · files = off) ────────────
# PLATFORM|COMPILER|CPU|YEAR|NOTES
_embedded_atari_ps5() {
  cat <<'AP'
atari2600|batari Basic|6502|2005|2600 BASIC compiler class
atari2600|dasm|6502|1987|Industry-standard 6502 assembler
atari2600|cc65|6502|1998|C compiler for 6502 (Atari 2600 banks)
atari2600|Stella SDK|6502|2000|Homebrew 2600 dev headers class
atari5200|cc65|6502|1998|Atari 5200 superchip targets
atari5200|MAC65|6502|1984|Atari macro assembler
atari5200|Atari Assembler|6502|1982|Official 5200 dev tools
atari7800|cc65|6502|1998|7800 Maria chip targets
atari7800|7800basic|6502|2015|BASIC-like 7800 compiler
atari7800|dasm|6502|1987|7800 asm via dasm syntax
atari8|cc65|6502|1998|Atari 8-bit OS targets
atari8|MAC65|6502|1984|Atari 8-bit official assembler
atari8|Atari Assembler|6502|1980|Cartridge development
atari8|GCC-6502|6502|2010|GCC port class for 6502 homebrew
atari8|Action!|6502|1983|Atari Action language compiler
atari8|Turbo BASIC XL|6502|1985|Fast BASIC compiler
atarist|Alcyon C|68000|1986|Official Atari ST C compiler
atarist|Pure C|68000|1990|Atari ST Pure C
atarist|GST C|68000|1985|Atari ST GST C compiler
atarist|MADMAC|68000|1984|Motorola macro assembler ST
atarist|m68k-elf-gcc|68000|1998|GNU cross GCC for 68000
atarist|AHCC|68000|1992|Atari ST ANSI C compiler
atarist|Lattice C|68000|1987|Lattice C on Atari ST
atarilynx|cc65|65C02|1998|Lynx 65C02 targets
atarilynx|GGP|65C02|1990|Lynx official dev kit class
atarilynx|lynx-asm|65C02|1989|Handy/Lynx assembler tools
atarijaguar|GASM|GPU|1992|Atari Jaguar GPU assembler
atarijaguar|Alcyon C|68000|1993|Jaguar 68000 C
atarijaguar|madmac|68000|1992|Jaguar MADMAC assembler
atarijaguar|jagbcc|RISC|1994|Jaguar homebrew C class
atarifalcon|Pure C|68030|1993|Atari Falcon Pure C
atarifalcon|AHCC|68030|1993|Falcon ANSI C
atarifalcon|m68k-elf-gcc|68030|1998|GNU GCC for Falcon
ps1|PSY-Q C|R3000|1990|Sony PS1 retail SDK compiler (catalog only)
ps1|PSY-Q ASM|R3000|1990|Sony PS1 assembler (catalog only)
ps1|PSXSDK gcc|R3000|2000|Open PS1 SDK GCC class (catalog only)
ps2|EE-GCC|R5900|1999|Sony PS2 Emotion Engine GCC
ps2|IOP-GCC|MIPS|1999|PS2 IOP MIPS GCC
ps2|mipsel-linux-gnu-gcc|R5900|2004|GNU MIPS cross PS2-era
ps2|PS2SDK gcc|R5900|2003|PS2SDK toolchain class
ps3|PPU-GCC|PowerPC64|2006|Sony Cell PPU GCC
ps3|SPU-GCC|SPU|2006|Sony Cell SPU GCC
ps3|powerpc64-linux-gnu-gcc|PowerPC64|2008|GNU PPC64 cross
ps3|PSL1GHT gcc|PowerPC64|2010|PS3 homebrew SDK GCC class
ps4|orbis-clang|x86_64|2014|Sony PS4 Orbis SDK clang
ps4|orbis-ld|x86_64|2014|Sony PS4 linker
ps4|clang x86_64|x86_64|2017|ORBIS SDK host clang (DevNet)
ps4|GCC x86_64|x86_64|2015|Host GCC for PS4 adjunct tools
ps5|prospero-clang|x86_64|2019|Sony PS5 Prospero SDK clang
ps5|prospero-ld|x86_64|2019|Sony PS5 linker
ps5|clang AMD64|x86_64|2020|Prospero host clang (DevNet)
ps5|LLVM PS5|x86_64|2021|PS5 LLVM backend class
AP
}

# ── GCC timeline 1930–2026 (embedded) ───────────────────────────────
# YEAR|VERSION|NOTES
_embedded_gcc() {
  cat <<'GCC'
1930|—|Pre-compiler era; numerical machines only
1936|—|Zuse Plankalkül design influences later algorithmic compilers
1954|—|FORTRAN I development begins (IBM); not GCC
1957|FORTRAN|IBM optimizing compiler — precursor ecosystem
1972|—|Unix C compiler (not GNU yet)
1984|—|GNU project founded; GCC not yet released
1987|GNU C 1.0|First GNU C compiler (Richard Stallman)
1988|GCC 1.27|Early GNU compiler collection
1989|GCC 1.37|Stabilized GNU C on Unix
1991|GCC 2.0|C++ front end integration begins
1992|GCC 2.3|C++ support matures
1993|GCC 2.4|Cross-compilation improvements
1994|GCC 2.5|EGCS fork precursor era
1995|GCC 2.6|Wide platform ports
1996|GCC 2.7|EGCS merge precursor
1997|EGCS 1.0|Experimental GNU branch (becomes GCC 2.95)
1998|GCC 2.8|GNU compiler collection cross mature
1999|GCC 2.95|Last 2.x line major release
2000|GCC 2.95.3|Stability release 2.x
2001|GCC 3.0|New middle-end architecture
2002|GCC 3.2|C++ standard library maturity
2003|GCC 3.3|Optimization improvements
2004|GCC 3.4|Stable cross prefix era
2005|GCC 4.0|Tree-SSA default
2006|GCC 4.1|Pointer analysis improvements
2007|GCC 4.2|OpenMP support begins
2008|GCC 4.3|C++0x features
2009|GCC 4.4|Graphite loop optimizations
2010|GCC 4.5|Interprocedural optimization
2011|GCC 4.6|C++0x default features
2012|GCC 4.7|C11 support
2013|GCC 4.8|C++11 complete on GCC
2014|GCC 4.9|C++14 draft support
2015|GCC 5.1|New versioning scheme
2016|GCC 6|C++14 default
2017|GCC 7|C++17 features
2018|GCC 8|C++17 era default
2019|GCC 9|C++2a draft
2020|GCC 10|C++20 partial
2021|GCC 11|C++20 default LTS class
2022|GCC 12|C++23 draft features
2023|GCC 13|C++23 partial support
2024|GCC 14|C++23 and Fortran improvements
2025|GCC 14.2|Current stable line
2026|GCC 15|catsdk catalog projection (files = off)
GCC
}

# General language compilers 1930–2026
_embedded_general() {
  cat <<'GEN'
1936|Zuse Plankalkül|concept|paper|First algorithmic language design
1957|FORTRAN|fortran|IBM704|First optimizing compiler
1958|LISP|lisp|IBM704|Recursive functions
1959|COBOL|cobol|various|Business language
1960|ALGOL60|algol|various|BNF block structure
1964|BASIC|basic|GE|Dartmouth BASIC
1970|Pascal|pascal|CDC|Niklaus Wirth
1972|C|c|PDP11|Unix systems language
1983|C++|c++|Bell|Stroustrup C with Classes
1987|Perl|perl|unix|Larry Wall
1990|Haskell|haskell|research|Pure functional
1991|Python|python|various|Guido van Rossum
1994|Java|java|JVM|Oak to Java
1995|Ruby|ruby|various|Yukihiro Matsumoto
1995|PHP|php|web|Rasmus Lerdorf
2000|C#|csharp|CLR|Microsoft .NET
2008|Go|go|native|Google Go
2010|Rust|rust|native|Mozilla Rust
2014|Swift|swift|darwin|Apple Swift
2020|Zig|zig|native|Andrew Kelley
2026|catsdk 1.0|meta|toolkit|Embedded catalog files = off
GEN
}

_has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ── ASM TOOLS (embedded · files = off) ──
# TOOL|ROLE|INSTALL|PLATFORMS|NOTES
_embedded_asm_tools() {
  cat <<'A'
cc65|6502 C compiler + toolchain|wget|atari2600,atari8,atari5200,atari7800,atarilynx|ca65+ld65 bundled
ca65|6502 macro assembler|bundled|6502-atari|part of cc65
ld65|6502 linker|bundled|6502-atari|part of cc65
dasm|6502 macro assembler|wget|atari2600,atari5200,atari7800|industry standard 6502 asm
MAC65|6502 macro assembler|catalog|atari8,atari5200|Atari official tool (historical)
GASM|Jaguar GPU assembler|catalog|atarijaguar|Atari Jaguar SDK (historical)
m68k-elf-gcc|68000 cross GCC|pkg|atarist,atarijaguar,atarifalcon|Atari ST/Falcon/Jaguar C/asm
as|GNU assembler|detect|host|from binutils
ld|GNU linker|detect|host|from binutils
gcc|host C/C++ compiler|detect|host|general development
A
}

# ── AUTODETECT + AUTOINSTALL (embedded toolchain table · files = off) ──
# BIN|PLATFORMS|METHOD|BREW|APT|EMBED_PKG|VER|SDK_ENV
_embedded_toolchains() {
  cat <<'T'
cc65|atari2600,atari5200,atari7800,atari8,atarilynx|wget|cc65|cc65|cc65|2.19|
ca65|atari6502|bundled|cc65|cc65|cc65|2.19|
ld65|atari6502|bundled|cc65|cc65|cc65|2.19|
dasm|atari2600,atari5200,atari7800|wget|dasm||dasm|2.20.14|
as|host|bundled|binutils|binutils|binutils|2.43|
ld|host|bundled|binutils|binutils|binutils|2.43|
m68k-elf-gcc|atarist,atarijaguar,atarifalcon|pkg|m68k-elf-gcc|gcc-m68k-linux-gnu|||
mipsel-linux-gnu-gcc|ps2|cross_gcc|mipsel-linux-gnu-binutils|gcc-mipsel-linux-gnu|gcc|12.4.0|
powerpc64-linux-gnu-gcc|ps3|cross_gcc|powerpc-elf-gcc|gcc-powerpc64-linux-gnu|gcc|12.4.0|
gcc|host|detect|gcc|gcc|gcc|14.2.0|
g++|host|detect|gcc|g++|gcc|14.2.0|
binutils|host|detect|binutils|binutils|binutils|2.43|
clang|host|pkg|llvm|clang|||
orbis-clang|ps4|sdk_env|SCE_ORBIS_SDK_DIR||||
prospero-clang|ps5|sdk_env|SCE_PROSPERO_SDK_DIR||||
T
}

_detect_host() {
  CATSDK_OS="$(uname -s)"
  CATSDK_ARCH="$(uname -m)"
  CATSDK_NCPU="$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 2)"
  CATSDK_PM="none"
  if _has_cmd brew; then CATSDK_PM="brew"
  elif _has_cmd apt-get; then CATSDK_PM="apt"
  elif _has_cmd dnf; then CATSDK_PM="dnf"
  elif _has_cmd pacman; then CATSDK_PM="pacman"
  fi
}

_detect_report() {
  _bold "autodetect"
  printf '  %-18s %s\n' "os" "${CATSDK_OS} (${CATSDK_ARCH})"
  printf '  %-18s %s\n' "cpus" "${CATSDK_NCPU}"
  printf '  %-18s %s\n' "package mgr" "${CATSDK_PM}"
  printf '  %-18s %s\n' "prefix" "${CATSDK_PREFIX}"
  printf '  %-18s %s\n' "wget" "$(_has_cmd wget && echo yes || echo no)"
  printf '  %-18s %s\n' "make" "$(_has_cmd make && echo yes || echo no)"
  echo ""
}

_has_compiler() {
  local bin="$1"
  _has_cmd "$bin" && return 0
  [ -x "${CATSDK_ROOT}/bin/${bin}" ] && return 0
  for p in "${PS2SDK:-}/bin" "${PS3SDK:-}/bin" \
           "${PS4SDK:-}/bin" "${PS5SDK:-}/bin" \
           /opt/homebrew/opt/llvm/bin /usr/local/opt/llvm/bin \
           /opt/homebrew/bin /usr/local/bin; do
    [ -n "$p" ] && [ -x "${p}/${bin}" ] && return 0
  done
  return 1
}

_sdk_path_is_placeholder() {
  case "${1:-}" in
    ""|/path/to/*|/path/*|*example*|*placeholder*) return 0 ;;
  esac
  return 1
}

_sdk_compiler_ok() {
  local envname="${1:-}" bin="$2" root=""
  [ -n "$envname" ] || return 1
  eval "root=\${${envname}:-}"
  _sdk_path_is_placeholder "$root" && return 1
  [ -n "$root" ] && [ -d "$root" ] && [ -x "${root}/host_tools/bin/${bin}" ]
}

_pkg_autodetect_skip() {
  local bin="${1:-}" brew_pkgs="${2:-}"
  # macOS brew: no mips/powerpc cross-gcc formulas — skip noise
  if [ "${CATSDK_PM:-}" = "brew" ]; then
    case "$bin" in
      mipsel-linux-gnu-gcc|powerpc64-*-gcc)
        local p
        IFS=',' read -ra _skip_try <<< "$brew_pkgs"
        for p in "${_skip_try[@]}"; do
          p="${p#"${p%%[![:space:]]*}"}"
          [[ "$p" == *gcc* ]] && _brew_formula_exists "$p" && return 1
        done
        return 0
        ;;
    esac
  fi
  return 1
}

_ensure_build_deps() {
  local missing=0
  _has_cmd wget || _has_cmd curl || missing=1
  _has_cmd make || missing=1
  if [ "$missing" -eq 0 ]; then return 0; fi
  _yellow "  installing build deps…"
  case "$CATSDK_PM" in
    brew)
      _has_cmd wget || brew install wget
      _has_cmd make || brew install make
      ;;
    apt)
      local apt=(apt-get install -y wget curl make patch gawk bzip2 xz-utils)
      if [ "$(id -u)" -eq 0 ]; then "${apt[@]}"
      elif _has_cmd sudo; then sudo "${apt[@]}"
      fi
      ;;
    dnf)
      if [ "$(id -u)" -eq 0 ]; then dnf install -y wget make patch gcc
      elif _has_cmd sudo; then sudo dnf install -y wget make patch gcc
      fi
      ;;
    pacman)
      if [ "$(id -u)" -eq 0 ]; then pacman -Sy --noconfirm wget make patch
      elif _has_cmd sudo; then sudo pacman -Sy --noconfirm wget make patch
      fi
      ;;
    *)
      _has_cmd wget || _has_cmd curl || { _red "need wget or curl"; return 1; }
      _has_cmd make || { _red "need make"; return 1; }
      ;;
  esac
}

_brew_formula_exists() {
  _has_cmd brew || return 1
  brew info --formula "$1" &>/dev/null
}

_try_brew_one() {
  local pkg="$1"
  _brew_formula_exists "$pkg" || return 1
  if brew list "$pkg" &>/dev/null; then
    _yellow "  brew $pkg already installed"
    return 0
  fi
  _cyan "  brew install $pkg"
  HOMEBREW_NO_ENV_HINTS=1 brew install "$pkg" || return 1
  return 0
}

_try_pkg() {
  local brew_pkgs="${1:-}" apt_pkg="${2:-}"
  case "$CATSDK_PM" in
    brew)
      [ -n "$brew_pkgs" ] || return 1
      local p tried=0 ok=0
      IFS=',' read -ra _brew_try <<< "$brew_pkgs"
      for p in "${_brew_try[@]}"; do
        p="${p#"${p%%[![:space:]]*}"}"
        p="${p%"${p##*[![:space:]]}"}"
        [ -z "$p" ] && continue
        tried=1
        if _try_brew_one "$p"; then ok=1; break; fi
      done
      [ "$ok" -eq 1 ] && return 0
      [ "$tried" -eq 1 ] && _yellow "  brew: no formula for ($brew_pkgs)"
      return 1
      ;;
    apt)
      [ -n "$apt_pkg" ] || return 1
      local cmd
      if [ "$(id -u)" -eq 0 ]; then cmd=(apt-get install -y "$apt_pkg")
      elif _has_cmd sudo; then cmd=(sudo apt-get install -y "$apt_pkg")
      else return 1; fi
      if dpkg -s "$apt_pkg" &>/dev/null; then
        _yellow "  apt $apt_pkg already installed"
      else
        _cyan "  apt install $apt_pkg"
        "${cmd[@]}" || return 1
      fi
      return 0
      ;;
    dnf)
      [ -n "$apt_pkg" ] || return 1
      local cmd
      if [ "$(id -u)" -eq 0 ]; then cmd=(dnf install -y "$apt_pkg")
      elif _has_cmd sudo; then cmd=(sudo dnf install -y "$apt_pkg")
      else return 1; fi
      _cyan "  dnf install $apt_pkg"
      "${cmd[@]}" || return 1
      return 0
      ;;
    pacman)
      [ -n "$brew_pkgs" ] || return 1
      local cmd pkg="${brew_pkgs%%,*}"
      if [ "$(id -u)" -eq 0 ]; then cmd=(pacman -S --noconfirm "$pkg")
      elif _has_cmd sudo; then cmd=(sudo pacman -S --noconfirm "$pkg")
      else return 1; fi
      _cyan "  pacman -S $pkg"
      "${cmd[@]}" || return 1
      return 0
      ;;
  esac
  return 1
}

_install_cross_fallback() {
  local bin="$1" brew_pkgs="$2"
  case "$bin" in
    mipsel-*|powerpc64-*)
      _yellow "  ${bin}: full cross-gcc not in brew — trying binutils companion"
      local b="${brew_pkgs%%,*}"
      case "$b" in
        *-gcc) b="${b/-gcc/-binutils}" ;;
      esac
      _try_pkg "$b" "" || true
      _yellow "  ${bin}: build from embedded gcc URL or use Linux/apt"
      return 1
      ;;
  esac
  return 1
}

_autodetect_missing() {
  local full="${1:-0}"
  local bin method brew apt embed ver sdk_env
  while IFS='|' read -r bin _plats method brew apt embed ver sdk_env; do
    [ -z "${bin:-}" ] && continue
    case "$method" in
      bundled) continue ;;
      sdk_env)
        _sdk_compiler_ok "$brew" "$bin" && continue
        printf 'missing|%s|sdk|%s\n' "$bin" "$brew"
        ;;
      detect|pkg|wget|cross_gcc)
        _has_compiler "$bin" && continue
        if [ "$full" != 1 ]; then
          case "$bin" in
            gcc|g++) _has_compiler clang && continue ;;
            binutils) _has_compiler as && _has_compiler ld && continue ;;
          esac
          _pkg_autodetect_skip "$bin" "$brew" && continue
          [ "$method" = "cross_gcc" ] && continue
        else
          case "$bin" in
            gcc|g++) _has_compiler clang && continue ;;
            binutils) _has_compiler as && _has_compiler ld && continue ;;
          esac
        fi
        printf 'missing|%s|%s|%s|%s|%s|%s\n' "$bin" "$method" "$brew" "$apt" "$embed" "$ver"
        ;;
    esac
  done < <(printf '%s\n' "$(_embedded_toolchains)")
}

# Core program bundle · FILES = OFF · wget/brew only (no catalog sidecars)
_autoinstall_programs() {
  _bold "programs · autoinstall"
  printf '  %-18s %s\n' "mode" "${CATSDK_TAG}"
  printf '  %-18s %s\n' "install prefix" "${CATSDK_ROOT}/bin"
  echo ""
  _install_cc65 "2.19" || true
  echo ""
  _install_dasm "2.20.14" || true
  echo ""
  _install_cross_brew_or_skip m68k-elf m68k-elf-gcc || true
  echo ""
  if ! _has_compiler clang; then
    _try_pkg llvm clang || true
    echo ""
  fi
  if ! _has_compiler nasm; then
    _try_brew_one nasm || true
    echo ""
  fi
  if ! _has_compiler as || ! _has_compiler ld; then
    _install_binutils "2.43" || true
    echo ""
  fi
  _install_tool_aliases || true
}

_probe_programs_report() {
  _bold "programs on PATH"
  local probes=(cc65 ca65 ld65 dasm as ld gas binutils m68k-elf-gcc nasm clang gcc wget make)
  local b ok=0 miss=0
  for b in "${probes[@]}"; do
    if _has_compiler "$b"; then
      printf '  [ok] %s\n' "$b"
      ok=$((ok + 1))
    else
      printf '  [--] %s\n' "$b"
      miss=$((miss + 1))
    fi
  done
  echo ""
  printf '  %s ready  %s missing\n' "$ok" "$miss"
}

_install_detected() {
  local bin="$1" method="$2" brew_pkg="$3" apt_pkg="$4" embed="${5:-}" ver="${6:-}"
  _bold "install · ${bin}"
  case "$method" in
    wget)
      case "$embed" in
        cc65) _install_cc65 "${ver:-2.19}"; return $? ;;
        dasm) _install_dasm "${ver:-2.20.14}"; return $? ;;
        binutils) _install_binutils "${ver:-2.43}"; return $? ;;
        gcc) _install_host_gcc "${ver:-14.2.0}"; return $? ;;
        *) _yellow "  no wget recipe for ${embed}"; return 1 ;;
      esac
      ;;
    detect)
      if _has_compiler "$bin"; then
        _green "  ${bin} found on system"
        return 0
      fi
      case "$embed" in
        gcc) _install_host_gcc "${ver:-14.2.0}"; return $? ;;
        binutils) _install_binutils "${ver:-2.43}"; return $? ;;
        *) _try_pkg "$brew_pkg" "$apt_pkg"; return $? ;;
      esac
      ;;
    pkg)
      if _has_compiler "$bin"; then
        _green "  ${bin} already on PATH"
        return 0
      fi
      if _try_pkg "$brew_pkg" "$apt_pkg"; then
        if _has_compiler "$bin"; then
          _green "  ${bin} via ${CATSDK_PM}"
          return 0
        fi
        _yellow "  ${brew_pkg}: installed but ${bin} not on PATH (no full cross-gcc in brew)"
        return 1
      fi
      _install_cross_fallback "$bin" "$brew_pkg" || true
      _yellow "  ${bin}: not available via ${CATSDK_PM} on this OS"
      return 1
      ;;
    cross_gcc)
      if _has_compiler "$bin"; then
        _green "  ${bin} already on PATH"
        return 0
      fi
      local triple="${bin%-gcc}"
      _install_cross_gcc_target "$triple" "${ver:-12.4.0}"
      ;;
  esac
}

_install_sdk_detected() {
  local bin="$1" envname="${2:-}" root=""
  [ -n "$envname" ] || { _yellow "  ${bin}: SDK env not configured"; return 1; }
  if _sdk_compiler_ok "$envname" "$bin"; then
    eval "root=\${${envname}:-}"
    _green "  ${bin} found (${envname}=${root})"
    return 0
  fi
  _yellow "  ${bin}: export ${envname}=/real/path/to/sony-sdk (not a placeholder)"
  return 1
}

_probe_everything_report() {
  _bold "toolchain probe"
  local probes=(
    cc65 ca65 ld65 dasm as ld gas binutils
    m68k-elf-gcc nasm clang gcc g++
    mipsel-linux-gnu-gcc powerpc64-linux-gnu-gcc
    orbis-clang prospero-clang
    wget make
  )
  local b ok=0 miss=0
  for b in "${probes[@]}"; do
    if _has_compiler "$b"; then
      printf '  [ok] %s\n' "$b"
      ok=$((ok + 1))
    else
      printf '  [--] %s\n' "$b"
      miss=$((miss + 1))
    fi
  done
  echo ""
  printf '  %s ready  %s missing\n' "$ok" "$miss"
  if ! _has_compiler orbis-clang || ! _has_compiler prospero-clang; then
    echo ""
    _yellow "  PS4/PS5: export SCE_ORBIS_SDK_DIR / SCE_PROSPERO_SDK_DIR (Sony DevNet)"
  fi
}

_autoinstall_everything() {
  set +e
  _detect_host
  _detect_report
  _ensure_build_deps || true
  _ensure_dirs
  _path_prepend "${CATSDK_ROOT}/bin"
  echo ""
  _bold "autoinstall everything · ${CATSDK_TAG}"
  _yellow "  catalogs in this file only · installs → ${CATSDK_PREFIX}"
  _yellow "  PS2/PS3 cross-GCC source builds may take 30–60+ min each"
  echo ""
  _autoinstall_programs
  echo ""
  _bold "Atari platforms"
  local p
  for p in atari2600 atari5200 atari7800 atari8 atarist atarilynx atarijaguar atarifalcon; do
    _autoinstall_platform "$p" || true
    echo ""
  done
  _bold "PlayStation PS2→PS5"
  _ensure_ps_dirs
  for p in ps2 ps3 ps4 ps5; do
    _autoinstall_platform "$p" || true
    echo ""
  done
  _bold "embedded toolchain catalog"
  echo ""
  local bin method brew apt embed ver sdk_env sdk_var
  local installed=0 skipped=0 failed=0
  while IFS='|' read -r tag bin method brew apt embed ver sdk_env; do
    [ "$tag" = "missing" ] || continue
    case "$bin" in
      ca65|ld65) continue ;;
    esac
    if [ "$method" = "sdk" ]; then
      sdk_var="${brew:-${sdk_env:-}}"
      if _install_sdk_detected "$bin" "$sdk_var"; then skipped=$((skipped+1))
      else failed=$((failed+1)); fi
    else
      if _install_detected "$bin" "$method" "$brew" "$apt" "$embed" "$ver"; then
        installed=$((installed+1))
      else
        failed=$((failed+1))
      fi
    fi
    echo ""
  done < <(_autodetect_missing 1)
  _install_tool_aliases || true
  _bold "autoinstall complete"
  printf '  installed/updated: %s  sdk/found: %s  manual/failed: %s\n' "$installed" "$skipped" "$failed"
  echo ""
  _probe_everything_report
  _print_shell_setup
  set -e
}

_run_autodetect_install() {
  _autoinstall_everything
}

_print_shell_setup() {
  echo ""
  _bold "shell setup (copy/paste)"
  echo "  eval \"\$($(printf '%q' "$CATSDK_FILE") env --prefix)\""
  echo ""
  _yellow "  after eval: binutils gas gasm lda65 live in ${CATSDK_ROOT}/bin"
  _yellow "  there is no system-wide binutils binary — use as/ld or the helper script"
  echo ""
  _bold "6502 (optional — only when building 6502)"
  echo "  export CC=cc65 CA65=ca65 LD65=ld65 DASM=dasm"
  echo ""
  _bold "command names"
  printf '  %-14s %s\n' "6502" "cc65 ca65 ld65 dasm"
  printf '  %-14s %s\n' "GNU asm" "as ld gas binutils(help) objcopy"
  printf '  %-14s %s\n' "prefix" "${CATSDK_ROOT}/bin"
}

_install_tool_aliases() {
  _ensure_dirs
  local b="${CATSDK_ROOT}/bin"
  if _has_compiler as && [ ! -e "${b}/gas" ]; then
    ln -sf "$(command -v as)" "${b}/gas" 2>/dev/null || true
  fi
  if _has_compiler ld65 && [ ! -e "${b}/lda65" ]; then
    ln -sf "$(command -v ld65)" "${b}/lda65" 2>/dev/null || true
  fi
  cat > "${b}/binutils" <<'BINUTILS_HELP'
#!/bin/sh
echo "GNU binutils — there is no single 'binutils' program."
echo "Use: as (assembler)  ld (linker)  objcopy  objdump  ar"
echo ""
for t in as ld objcopy objdump ar; do
  command -v "$t" >/dev/null 2>&1 && printf '  [ok] %s\n' "$t" || printf '  [--] %s\n' "$t"
done
BINUTILS_HELP
  chmod +x "${b}/binutils" 2>/dev/null || true
  cat > "${b}/gasm" <<'GASM_HELP'
#!/bin/sh
echo "GASM: Atari Jaguar GPU assembler (historical retail SDK tool)."
echo "Not wget-able. Use m68k-elf-gcc + cc65/dasm for modern homebrew."
GASM_HELP
  chmod +x "${b}/gasm" 2>/dev/null || true
  _path_prepend "${b}"
}

_mirror_url() {
  local pkg="${1:-}" ver="${2:-}"
  printf '%s\n' "$(_embedded_mirrors)" | awk -F'|' -v p="$pkg" -v v="$ver" '$1==p && $2==v {print $3; exit}'
}

_mirror_urls() {
  local pkg="${1:-}" ver="${2:-}"
  printf '%s\n' "$(_embedded_mirrors)" | awk -F'|' -v p="$pkg" -v v="$ver" '$1==p && $2==v {print $3}'
}

_fetch_first_mirror() {
  local pkg="${1:-}" ver="${2:-}" dest="${3:-}"
  local url url_base
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    url_base=$(basename "${url%%\?*}")
    local try_dest="${dest:-${CATSDK_SRC}/${url_base}}"
    if _fetch "$url" "$try_dest"; then
      # Return path via global for caller (bash 3.2 safe)
      _CATSDK_LAST_FETCH="$try_dest"
      return 0
    fi
    _yellow "  mirror failed, trying next…"
    rm -f "$try_dest"
  done < <(_mirror_urls "$pkg" "$ver")
  _red "  all mirrors failed for ${pkg}-${ver}"
  return 1
}

_ensure_dirs() {
  mkdir -p "$CATSDK_SRC" "$CATSDK_ROOT/bin" "$CATSDK_ROOT/lib"
}

_path_prepend() {
  local dir="${1:-}"
  [ -n "$dir" ] || return 0
  case ":${PATH}:" in
    *:"$dir":*) ;;
    *) export PATH="$dir:$PATH" ;;
  esac
  for p in /opt/homebrew/opt/llvm/bin /usr/local/opt/llvm/bin; do
    case ":${PATH}:" in
      *:"$p":*) ;;
      *) [ -d "$p" ] && export PATH="$p:$PATH" ;;
    esac
  done
}

# Real host C/C++ for gnu.org source builds — never cc65 from a prior eval.
_host_cc() {
  local c
  if [ "$(uname -s)" = "Darwin" ]; then
    c="$(xcrun -find clang 2>/dev/null)" && [ -n "$c" ] && [ -x "$c" ] && { printf '%s\n' "$c"; return 0; }
  fi
  c="$(command -v clang 2>/dev/null)" && [ -n "$c" ] && { printf '%s\n' "$c"; return 0; }
  c="$(command -v gcc 2>/dev/null)" && [ -n "$c" ] && { printf '%s\n' "$c"; return 0; }
  printf '%s\n' gcc
}

_host_cxx() {
  local c
  if [ "$(uname -s)" = "Darwin" ]; then
    c="$(xcrun -find clang++ 2>/dev/null)" && [ -n "$c" ] && [ -x "$c" ] && { printf '%s\n' "$c"; return 0; }
  fi
  c="$(command -v clang++ 2>/dev/null)" && [ -n "$c" ] && { printf '%s\n' "$c"; return 0; }
  c="$(command -v g++ 2>/dev/null)" && [ -n "$c" ] && { printf '%s\n' "$c"; return 0; }
  printf '%s\n' g++
}

_host_build_path() {
  local p clean="" part
  for part in /usr/bin /bin /usr/sbin /sbin /opt/homebrew/bin /usr/local/bin \
              /Library/Developer/CommandLineTools/usr/bin; do
    [ -d "$part" ] && clean="${clean:+$clean:}$part"
  done
  IFS=':' read -ra _hbp <<< "${PATH:-}"
  for part in "${_hbp[@]}"; do
    [ -z "$part" ] && continue
    case "$part" in
      "${CATSDK_ROOT}/bin"|"${CATSDK_PREFIX}"|"${CATSDK_PREFIX}/"*) continue ;;
    esac
    case ":$clean:" in
      *:"$part":*) ;;
      *) [ -d "$part" ] && clean="${clean:+$clean:}$part" ;;
    esac
  done
  printf '%s\n' "$clean"
}

_with_host_build() {
  local host_cc host_cxx host_path sdk
  host_cc="$(_host_cc)"
  host_cxx="$(_host_cxx)"
  host_path="$(_host_build_path)"
  (
    unset CC CXX AR RANLIB LD CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
    export CC="$host_cc" CXX="$host_cxx" PATH="$host_path"
    if [ "$(uname -s)" = "Darwin" ]; then
      sdk="$(xcrun --show-sdk-path 2>/dev/null)" && [ -n "$sdk" ] && export SDKROOT="$sdk"
      [ -n "$(xcode-select -p 2>/dev/null)" ] && export DEVELOPER_DIR="$(xcode-select -p 2>/dev/null)"
    fi
    "$@"
  )
}

_CATSdk_FETCH_UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
_CATSDK_LAST_FETCH=""

_archive_sanity() {
  local dest="$1"
  [ -f "$dest" ] || return 1
  local sz
  sz=$(wc -c <"$dest" | tr -d ' ')
  [ "${sz:-0}" -gt 1024 ] || return 1
  case "$dest" in
    *.tar.gz|*.tgz)  tar -tzf "$dest" 2>/dev/null | head -1 | grep -q . ;;
    *.tar.bz2|*.tbz2) tar -tjf "$dest" 2>/dev/null | head -1 | grep -q . ;;
    *.tar.xz|*.txz)  tar -tJf "$dest" 2>/dev/null | head -1 | grep -q . ;;
    *) return 0 ;;
  esac
}

_fetch() {
  local url="$1" dest="$2"
  if [ -f "$dest" ]; then
    if _archive_sanity "$dest"; then
      _yellow "  cached: ${dest##*/}"
      return 0
    fi
    _yellow "  purging bad cache: ${dest##*/}"
    rm -f "$dest"
  fi
  if _has_cmd wget; then
    _cyan "  wget ${url}"
    wget -q --show-progress -O "$dest" \
      --user-agent="${_CATSdk_FETCH_UA}" \
      --timeout=90 --tries=2 \
      -L \
      "$url" || return 1
  elif _has_cmd curl; then
    _cyan "  curl ${url}"
    curl -fSL --max-time 90 \
      -A "${_CATSdk_FETCH_UA}" \
      -o "$dest" \
      "$url" || return 1
  else
    _red "wget or curl required for autoinstall"
    return 1
  fi
  _archive_sanity "$dest"
}

_install_cc65() {
  local ver="${1:-2.19}"
  if _has_compiler cc65 && _has_compiler ca65 && _has_compiler ld65; then
    _green "  cc65/ca65/ld65 already available"
    return 0
  fi
  local url name="cc65-${ver}"
  url="$(_mirror_url cc65 "$ver")"
  [ -n "$url" ] || { _red "no embedded cc65 URL"; return 1; }
  _ensure_dirs
  local arc="${CATSDK_SRC}/${name}.tar.bz2"
  _fetch_first_mirror cc65 "$ver" "$arc" || return 1
  local dir="${CATSDK_SRC}/${name}"
  [ -d "$dir" ] || tar -xjf "$arc" -C "$CATSDK_SRC" || return 1
  _cyan "  make cc65 PREFIX=${CATSDK_ROOT}"
  make -C "$dir" PREFIX="$CATSDK_ROOT" -j"${CATSDK_NCPU:-2}" install || return 1
  _has_compiler cc65 && _has_compiler ca65 && _has_compiler ld65 || { _red "  cc65 install incomplete"; return 1; }
  _path_prepend "${CATSDK_ROOT}/bin"
  _green "  cc65/ca65/ld65 installed → ${CATSDK_ROOT}/bin"
}

_install_dasm() {
  local ver="${1:-2.20.14}"
  if _has_compiler dasm; then
    _green "  dasm already available"
    return 0
  fi
  _ensure_dirs
  if [ "${CATSDK_PM:-}" = "brew" ] && _brew_formula_exists dasm; then
    if _try_brew_one dasm && _has_compiler dasm; then
      local brew_dasm
      brew_dasm="$(command -v dasm)"
      install -m 755 "$brew_dasm" "${CATSDK_ROOT}/bin/dasm" 2>/dev/null || true
      _path_prepend "${CATSDK_ROOT}/bin"
      _green "  dasm via brew → ${brew_dasm}"
      return 0
    fi
  fi
  local arc="${CATSDK_SRC}/dasm-${ver}.tar.gz"
  _fetch_first_mirror dasm "$ver" "$arc" || return 1
  arc="${_CATSDK_LAST_FETCH:-$arc}"
  tar -xzf "$arc" -C "$CATSDK_SRC" 2>/dev/null || { _red "dasm extract failed"; return 1; }
  local root="" src="" candidate built=""
  for candidate in \
    "${CATSDK_SRC}/dasm-2.20.14.1" \
    "${CATSDK_SRC}/dasm-${ver}-src" \
    "${CATSDK_SRC}/dasm-${ver}" \
    "${CATSDK_SRC}/2.20.14.1" \
    "$(find "$CATSDK_SRC" -maxdepth 1 -type d \( -name 'dasm-*' -o -name '2.20.14.*' \) 2>/dev/null | head -1)"; do
    [ -n "$candidate" ] && [ -d "$candidate" ] && root="$candidate" && break
  done
  [ -n "$root" ] || { _red "  dasm extract dir missing under ${CATSDK_SRC}"; ls -la "$CATSDK_SRC" 2>/dev/null | head -8; return 1; }
  if [ -f "${root}/Makefile" ]; then
    _cyan "  make dasm in ${root}"
    make -C "$root" -j"${CATSDK_NCPU:-2}" || { _red "  dasm make failed"; return 1; }
    for candidate in "${root}/bin/dasm" "${root}/dasm"; do
      [ -x "$candidate" ] && built="$candidate" && break
    done
  fi
  if [ -z "$built" ]; then
    if [ -f "${root}/src/Makefile" ] || [ -f "${root}/src/dasm.c" ]; then
      src="${root}/src"
    elif [ -f "${root}/dasm.c" ]; then
      src="$root"
    else
      candidate=$(find "$root" -maxdepth 2 -type f -name 'dasm.c' 2>/dev/null | head -1)
      [ -n "$candidate" ] && src="$(dirname "$candidate")"
    fi
    [ -n "$src" ] && [ -d "$src" ] || { _red "  dasm Makefile not found in ${root}"; return 1; }
    _cyan "  make dasm in ${src}"
    make -C "$src" -j"${CATSDK_NCPU:-2}" || { _red "  dasm make failed"; return 1; }
    for candidate in "${src}/dasm" "${root}/dasm" "${src}/src/dasm"; do
      [ -x "$candidate" ] && built="$candidate" && break
    done
  fi
  [ -n "$built" ] || built=$(find "$root" -maxdepth 3 -type f -name dasm -perm -111 2>/dev/null | head -1)
  [ -n "$built" ] && [ -x "$built" ] || { _red "  dasm binary not built"; return 1; }
  install -m 755 "$built" "${CATSDK_ROOT}/bin/dasm" || return 1
  _path_prepend "${CATSDK_ROOT}/bin"
  _green "  dasm installed → ${CATSDK_ROOT}/bin/dasm"
}

_retro_asm_note() {
  local tool="$1" notes="$2"
  _yellow "  ${tool}: ${notes}"
  _yellow "    (catalog/historical · use cc65/dasm for modern 6502 asm)"
}

_install_asm_all() {
  _bold "autoinstall · all ASM toolchains"
  _install_cc65 "2.19" || true
  _install_dasm "2.20.14" || true
  _install_binutils "2.43" || true
  _install_host_gcc "14.2.0" || true
  _install_cross_brew_or_skip m68k-elf m68k-elf-gcc || true
  _retro_asm_note MAC65 "Atari macro assembler · Atari 8-bit/5200 official SDK"
  _retro_asm_note GASM "Jaguar GPU assembler · Atari Jaguar SDK"
  _green "  ASM bundle: cc65+ca65+ld65 · dasm · binutils(as/ld) · host gcc"
}

_install_binutils() {
  local ver="${1:-2.43}"
  if _has_compiler ld && _has_compiler as; then
    _green "  binutils already available"
    return 0
  fi
  local url name="binutils-${ver}"
  url="$(_mirror_url binutils "$ver")"
  [ -n "$url" ] || return 1
  _ensure_dirs
  local arc="${CATSDK_SRC}/${name}.tar.xz"
  _fetch "$url" "$arc"
  local dir="${CATSDK_SRC}/${name}"
  [ -d "$dir" ] || tar -xJf "$arc" -C "$CATSDK_SRC"
  _patch_binutils_darwin "$dir"
  local b="${CATSDK_SRC}/build-binutils-${ver}"
  mkdir -p "$b"
  if [ ! -x "${CATSDK_ROOT}/bin/ld" ]; then
    _cyan "  configure binutils → ${CATSDK_ROOT}"
    _with_host_build bash -c "cd $(printf '%q' "$b") && $(printf '%q' "$dir/configure") --prefix=$(printf '%q' "$CATSDK_ROOT") --disable-werror && make -j${CATSDK_NCPU:-2} && make install" || return 1
  else
    _yellow "  binutils already in ${CATSDK_ROOT}"
  fi
  _path_prepend "${CATSDK_ROOT}/bin"
  _green "  binutils → as ld objcopy in ${CATSDK_ROOT}/bin or system PATH"
}

_install_host_gcc() {
  local ver="${1:-14.2.0}"
  if _has_compiler gcc && _has_compiler g++; then
    _green "  host gcc/g++ already on PATH"
    return 0
  fi
  _install_binutils || true
  local url name="gcc-${ver}"
  url="$(_mirror_url gcc "$ver")"
  [ -n "$url" ] || return 1
  _ensure_dirs
  local arc="${CATSDK_SRC}/${name}.tar.xz"
  _fetch "$url" "$arc"
  local dir="${CATSDK_SRC}/${name}"
  [ -d "$dir" ] || tar -xJf "$arc" -C "$CATSDK_SRC"
  _patch_gcc_darwin_cross "$dir"
  local b="${CATSDK_SRC}/build-gcc-host-${ver}"
  mkdir -p "$b"
  if [ ! -x "${CATSDK_ROOT}/bin/gcc" ]; then
    _cyan "  configure host gcc (this can take a while)…"
    _with_host_build bash -c "cd $(printf '%q' "$b") && $(printf '%q' "$dir/configure") --prefix=$(printf '%q' "$CATSDK_ROOT") --enable-languages=c,c++ --disable-multilib && make -j${CATSDK_NCPU:-2} && make install" || return 1
  fi
  _path_prepend "${CATSDK_ROOT}/bin"
  _green "  host gcc installed"
}

# ── PlayStation platform layout (imported from catsdk-ps1-ps4 · files = off) ──
CATSDK_PS="${CATSDK_PS:-${CATSDK_PREFIX}/playstation}"
PS2SDK="${PS2SDK:-${CATSDK_PS}/ps2}"
PS3SDK="${PS3SDK:-${CATSDK_PS}/ps3}"
PS4SDK="${PS4SDK:-${CATSDK_PS}/ps4}"
PS5SDK="${PS5SDK:-${CATSDK_PS}/ps5}"

_ensure_ps_dirs() {
  mkdir -p "${PS2SDK}/bin" "${PS3SDK}/bin" \
           "${PS4SDK}/bin" "${PS5SDK}/bin" "${CATSDK_PS}/notes"
}

_link_cross_to_ps_bins() {
  local target="${1:-}" plat="${2:-}" b name
  [ -n "$target" ] && [ -n "$plat" ] || return 0
  case "$plat" in
    ps2) b="${PS2SDK}/bin" ;;
    ps3) b="${PS3SDK}/bin" ;;
    *) return 0 ;;
  esac
  mkdir -p "$b"
  for name in "${target}-gcc" "${target}-g++" "${target}-as" "${target}-ld" \
              "${target}-objcopy" "${target}-objdump" "${target}-ar"; do
    [ -x "${CATSDK_ROOT}/bin/${name}" ] && ln -sf "${CATSDK_ROOT}/bin/${name}" "${b}/${name}" 2>/dev/null || true
  done
}

_triple_for_ps() {
  case "$1" in
    ps2) echo "mipsel-linux-gnu" ;;
    ps3) echo "powerpc64-linux-gnu" ;;
  esac
}

_try_brew_cask() {
  local cask="$1"
  _has_cmd brew || return 1
  if brew list --cask "$cask" &>/dev/null 2>&1; then
    _yellow "  brew cask $cask already installed"
    return 0
  fi
  _cyan "  brew install --cask $cask"
  if HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_AUTO_UPDATE=1 \
     brew install --cask "$cask" &>/dev/null; then
    return 0
  fi
  _yellow "  brew cask $cask not available"
  return 1
}

_discover_sony_sdk() {
  local label="$1" envname="$2" bin="$3"
  local cur="" candidate root=""
  eval "cur=\${${envname}:-}"
  if ! _sdk_path_is_placeholder "$cur" && [ -d "$cur" ] && [ -x "${cur}/host_tools/bin/${bin}" ]; then
    _green "  ${label}: ${envname}=${cur}"
    return 0
  fi
  for candidate in \
    "$cur" \
    "${HOME}/OpenOrbis" \
    "${HOME}/openorbis" \
    "${HOME}/ps4dev" \
    "${HOME}/PS4_SDK" \
    "${HOME}/Orbis_SDK" \
    "${HOME}/prospero" \
    "${HOME}/ps5dev" \
    "${HOME}/PS5_SDK" \
    "/opt/sony/${label}" \
    "/usr/local/sony/${label}"; do
    [ -z "$candidate" ] && continue
    _sdk_path_is_placeholder "$candidate" && continue
    [ -d "$candidate" ] || continue
    if [ -x "${candidate}/host_tools/bin/${bin}" ]; then
      root="$candidate"
      break
    fi
    if [ -x "${candidate}/bin/${bin}" ]; then
      root="$candidate"
      break
    fi
  done
  if [ -n "$root" ]; then
    eval "export ${envname}=\"${root}\""
    _green "  ${label}: auto-set ${envname}=${root}"
    return 0
  fi
  _yellow "  ${label}: set ${envname}=/real/path/to/sony-sdk (not a placeholder)"
  return 1
}

_wire_sony_sdk_bins() {
  local envname="$1" bin="$2" ps_bin_dir="$3"
  local root="" src=""
  eval "root=\${${envname}:-}"
  _sdk_path_is_placeholder "$root" && return 1
  [ -d "$root" ] || return 1
  for src in \
    "${root}/host_tools/bin/${bin}" \
    "${root}/bin/${bin}"; do
    [ -x "$src" ] || continue
    mkdir -p "${CATSDK_ROOT}/bin" "$ps_bin_dir"
    ln -sf "$src" "${CATSDK_ROOT}/bin/${bin}" 2>/dev/null || true
    ln -sf "$src" "${ps_bin_dir}/${bin}" 2>/dev/null || true
    _green "  ${bin} → ${ps_bin_dir}/${bin}"
    return 0
  done
  return 1
}

_install_ps_platform() {
  local id="$1"
  _ensure_ps_dirs
  case "$id" in
    ps2)
      _try_brew_cask pcsx2 || true
      ;;
    ps3)
      _try_brew_cask rpcs3 || true
      ;;
    ps4)
      _discover_sony_sdk "orbis" "SCE_ORBIS_SDK_DIR" "orbis-clang" || true
      _wire_sony_sdk_bins "SCE_ORBIS_SDK_DIR" "orbis-clang" "${PS4SDK}/bin" || true
      _wire_sony_sdk_bins "SCE_ORBIS_SDK_DIR" "orbis-ld" "${PS4SDK}/bin" || true
      ;;
    ps5)
      _discover_sony_sdk "prospero" "SCE_PROSPERO_SDK_DIR" "prospero-clang" || true
      _wire_sony_sdk_bins "SCE_PROSPERO_SDK_DIR" "prospero-clang" "${PS5SDK}/bin" || true
      _wire_sony_sdk_bins "SCE_PROSPERO_SDK_DIR" "prospero-ld" "${PS5SDK}/bin" || true
      ;;
  esac
}

_ensure_cross_build_deps() {
  _ensure_build_deps || return 1
  case "${CATSDK_PM:-}" in
    brew)
      for pkg in gmp mpfr libmpc gnu-sed texinfo bison; do
        _brew_formula_exists "$pkg" && _try_brew_one "$pkg" || true
      done
      ;;
    apt)
      local apt=(gcc g++ make texinfo bison flex libgmp-dev libmpfr-dev libmpc-dev)
      if [ "$(id -u)" -eq 0 ]; then apt-get install -y "${apt[@]}" 2>/dev/null || true
      elif _has_cmd sudo; then sudo apt-get install -y "${apt[@]}" 2>/dev/null || true
      fi
      ;;
  esac
}

_apply_brew_cross_flags() {
  [ "${CATSDK_PM:-}" = "brew" ] || return 0
  _has_cmd brew || return 0
  local bp f
  bp="$(brew --prefix 2>/dev/null)" || return 0
  for f in gmp mpfr libmpc; do
    [ -d "${bp}/opt/${f}/include" ] && CPPFLAGS="-I${bp}/opt/${f}/include ${CPPFLAGS:-}"
    [ -d "${bp}/opt/${f}/lib" ] && LDFLAGS="-L${bp}/opt/${f}/lib ${LDFLAGS:-}"
  done
  if _brew_formula_exists gnu-sed; then
    export PATH="${bp}/opt/gnu-sed/libexec/gnubin:${PATH}"
  fi
  export CPPFLAGS LDFLAGS
}

_patch_zlib_darwin() {
  local root="${1:-}" zutil
  [ -n "$root" ] || return 0
  [ "$(uname -s)" = "Darwin" ] || return 0
  zutil="${root}/zutil.h"
  [ -f "$zutil" ] || return 0
  if grep -q 'define fdopen(fd,mode) NULL' "$zutil" 2>/dev/null; then
    _cyan "  patching zlib for macOS (${zutil##*/})"
    sed -i.bak '/define fdopen(fd,mode) NULL/d' "$zutil" 2>/dev/null || \
      sed -i '' '/define fdopen(fd,mode) NULL/d' "$zutil" 2>/dev/null || true
  fi
}

_patch_binutils_darwin() {
  local bu_dir="$1"
  [ -d "$bu_dir" ] || return 0
  _patch_zlib_darwin "${bu_dir}/zlib"
}

_patch_gcc_darwin_cross() {
  local gcc_dir="$1" f="${gcc_dir}/gcc/config.host"
  [ -d "$gcc_dir" ] || return 0
  _patch_zlib_darwin "${gcc_dir}/zlib"
  [ -f "$f" ] || return 0
  [ "$(uname -s)" = "Darwin" ] || return 0
  if grep -q 'TARGET_OS_MAC' "$f" 2>/dev/null; then
    _cyan "  patching gcc config.host for macOS cross"
    sed -i.bak 's/defined(MACOS) || defined(TARGET_OS_MAC)/defined(MACOS)/' "$f" 2>/dev/null || \
      sed -i '' 's/defined(MACOS) || defined(TARGET_OS_MAC)/defined(MACOS)/' "$f" 2>/dev/null || true
  fi
}

_fetch_binutils_source() {
  local bu_ver="${1:-2.43}" bu_name="binutils-${bu_ver}" bu_arc bu_dir
  bu_arc="${CATSDK_SRC}/${bu_name}.tar.xz"
  if ! _fetch_first_mirror binutils "$bu_ver" "$bu_arc"; then
    if [ "$bu_ver" = "2.46.1" ]; then
      _yellow "  binutils-2.46.1 unavailable — falling back to 2.43"
      _fetch_binutils_source 2.43
      return $?
    fi
    return 1
  fi
  bu_arc="${_CATSDK_LAST_FETCH:-$bu_arc}"
  bu_dir="${CATSDK_SRC}/${bu_name}"
  if [ ! -d "$bu_dir" ]; then
    case "$bu_arc" in
      *.tar.gz|*.tgz) tar -xzf "$bu_arc" -C "$CATSDK_SRC" ;;
      *) tar -xJf "$bu_arc" -C "$CATSDK_SRC" ;;
    esac || return 1
  fi
  _patch_binutils_darwin "$bu_dir"
  printf '%s\n' "$bu_dir"
}

_install_cross_gcc_target() {
  local target="${1:-}" gcc_ver="${2:-12.4.0}" bu_ver="${3:-}"
  [ -n "$bu_ver" ] || bu_ver="2.46.1"
  [ "$(uname -s)" = "Darwin" ] && [ -f "${CATSDK_SRC}/binutils-2.43.tar.xz" ] && bu_ver="2.43"
  local gcc_bin="${target}-gcc" plat=""
  [ -n "$target" ] || return 1
  case "$target" in
    mipsel-linux-gnu) plat="ps2" ;;
    powerpc64-linux-gnu) plat="ps3" ;;
  esac
  if _has_compiler "$gcc_bin"; then
    _green "  ${gcc_bin} already available"
    _link_cross_to_ps_bins "$target" "$plat"
    return 0
  fi
  if [ "${CATSDK_PM:-}" = "apt" ]; then
    local apt_pkg="gcc-${target}"
    if _try_pkg "" "$apt_pkg" && _has_compiler "$gcc_bin"; then
      _green "  ${gcc_bin} via apt"
      _link_cross_to_ps_bins "$target" "$plat"
      return 0
    fi
  fi
  if [ "${CATSDK_PM:-}" = "brew" ]; then
    case "$target" in
      mipsel-*)
        _try_brew_one mipsel-linux-gnu-binutils || true
        ;;
    esac
  fi
  _ensure_cross_build_deps || return 1
  _ensure_dirs
  _ensure_ps_dirs
  _cyan "  building ${target} cross toolchain (gnu.org · may take 15–45 min)…"
  local bu_dir bu_build
  bu_dir="$(_fetch_binutils_source "${bu_ver}")" || return 1
  bu_build="${CATSDK_SRC}/build-${target}-binutils-${bu_ver}"
  rm -rf "$bu_build"
  mkdir -p "$bu_build"
  if [ ! -x "${CATSDK_ROOT}/bin/${target}-as" ]; then
    _cyan "  configure binutils --target=${target}"
    _with_host_build bash -c "cd $(printf '%q' "$bu_build") && $(printf '%q' "$bu_dir/configure") --target=$(printf '%q' "$target") --prefix=$(printf '%q' "$CATSDK_ROOT") --disable-nls --disable-werror && make -j${CATSDK_NCPU:-2} && make install" || {
      _red "  binutils cross build failed for ${target}"
      return 1
    }
  fi
  local gcc_name="gcc-${gcc_ver}" gcc_arc gcc_dir gcc_build
  gcc_arc="${CATSDK_SRC}/${gcc_name}.tar.xz"
  _fetch_first_mirror gcc "$gcc_ver" "$gcc_arc" || return 1
  gcc_arc="${_CATSDK_LAST_FETCH:-$gcc_arc}"
  gcc_dir="${CATSDK_SRC}/${gcc_name}"
  [ -d "$gcc_dir" ] || tar -xJf "$gcc_arc" -C "$CATSDK_SRC" || return 1
  if [ -x "${gcc_dir}/contrib/download_prerequisites" ]; then
    (cd "$gcc_dir" && ./contrib/download_prerequisites) 2>/dev/null || true
  fi
  _patch_gcc_darwin_cross "$gcc_dir"
  gcc_build="${CATSDK_SRC}/build-${target}-gcc-${gcc_ver}"
  rm -rf "$gcc_build"
  mkdir -p "$gcc_build"
  if [ ! -x "${CATSDK_ROOT}/bin/${gcc_bin}" ]; then
    _cyan "  configure gcc --target=${target} (host CC=$(_host_cc))"
    _with_host_build bash -c "cd $(printf '%q' "$gcc_build") && $(printf '%q' "$gcc_dir/configure") --target=$(printf '%q' "$target") --prefix=$(printf '%q' "$CATSDK_ROOT") --enable-languages=c,c++ --disable-nls --without-headers --without-isl --disable-shared --disable-multilib --disable-libssp --disable-werror --with-as=$(printf '%q' "${CATSDK_ROOT}/bin/${target}-as") --with-ld=$(printf '%q' "${CATSDK_ROOT}/bin/${target}-ld")" || {
      _red "  gcc cross configure failed for ${target}"
      return 1
    }
    _cyan "  make gcc --target=${target} (this takes a while)…"
    _with_host_build bash -c "cd $(printf '%q' "$gcc_build") && make -j${CATSDK_NCPU:-2} all-gcc && make install-gcc" || {
      _red "  gcc cross build failed for ${target}"
      return 1
    }
  fi
  _path_prepend "${CATSDK_ROOT}/bin"
  _link_cross_to_ps_bins "$target" "$plat"
  _has_compiler "$gcc_bin" || { _red "  ${gcc_bin} not on PATH after build"; return 1; }
  _green "  ${gcc_bin} installed → ${CATSDK_ROOT}/bin/${gcc_bin}"
  [ -n "$plat" ] && _green "  also linked → ${CATSDK_PS}/${plat}/bin/"
  return 0
}

_install_cross_brew_or_skip() {
  local triple="$1"
  local brew_pkg="$2"
  if _has_compiler "${triple}-gcc"; then
    _yellow "  ${triple}-gcc already on PATH"
    return 0
  fi
  if _brew_formula_exists "$brew_pkg" && _try_brew_one "$brew_pkg"; then
    _has_compiler "${triple}-gcc" && _green "  ${triple}-gcc via brew" && return 0
  fi
  _install_cross_gcc_target "$triple" "12.4.0"
}

cmd_import_playstation() {
  banner
  _bold "import playstation · PS2→PS5 (embedded from catsdk-ps1-ps4 · files = off)"
  echo ""
  _ensure_build_deps || true
  _ensure_ps_dirs
  local p triple
  for p in ps2 ps3 ps4 ps5; do
    _install_ps_platform "$p"
    triple="$(_triple_for_ps "$p")"
    if [ -n "$triple" ]; then
      _install_cross_gcc_target "$triple" "12.4.0" || true
    fi
    echo ""
  done
  _install_tool_aliases || true
  _bold "import complete"
  _print_shell_setup
  echo ""
  _bold "PlayStation compiler checks"
  local probes=(
    mipsel-linux-gnu-gcc
    powerpc64-linux-gnu-gcc
    orbis-clang
    prospero-clang
  )
  for b in "${probes[@]}"; do
    if _has_compiler "$b"; then printf '  [ok] %s\n' "$b"
    else printf '  [--] %s\n' "$b"; fi
  done
}

cmd_import() {
  local what="${1:-playstation}"
  local id
  id="$(echo "$what" | tr '[:upper:]' '[:lower:]')"
  case "$id" in
    playstation|ps|ps2-ps5)
      cmd_import_playstation
      ;;
    ps2|ps3|ps4|ps5)
      banner
      _bold "import · ${id}"
      _ensure_build_deps || true
      _install_ps_platform "$id"
      local triple
      triple="$(_triple_for_ps "$id")"
      [ -n "$triple" ] && _install_cross_gcc_target "$triple" "12.4.0" || true
      _install_tool_aliases || true
      _print_shell_setup
      ;;
    *.sh)
      _red "FILES = OFF — logic from companion .sh is embedded; use: catsdk.sh import playstation"
      _yellow "  merged: catsdk-ps1-ps4-m4pro-no-github.sh · catsdk-atari-ps5-m4pro-no-github.sh"
      return 1
      ;;
    *)
      _red "Usage: catsdk.sh import playstation|ps2|ps3|ps4|ps5"
      return 1
      ;;
  esac
}

_autoinstall_platform() {
  local id="$1"
  _bold "autoinstall · ${id}"
  case "$id" in
    cc65) _install_cc65 ;;
    dasm) _install_dasm ;;
    asm|asm-all) _install_asm_all ;;
    atari2600|atari5200|atari7800)
      _install_cc65
      _install_dasm ;;
    atari8|atarilynx)
      _install_cc65
      _install_dasm
      _retro_asm_note MAC65 "Atari 8-bit macro assembler (also used on 5200)" ;;
    atarist|atarifalcon)
      _install_cross_brew_or_skip m68k-elf m68k-elf-gcc
      _install_cc65 ;;
    atarijaguar)
      _install_cross_brew_or_skip m68k-elf m68k-elf-gcc
      _install_cc65
      _retro_asm_note GASM "Jaguar GPU assembler (madmac for 68000 in catalog)" ;;
    ps1)
      _yellow "  PS1 compiler removed — catalog-only (see list-chain ps1)"
      ;;
    ps2)
      _install_ps_platform ps2
      _install_cross_gcc_target mipsel-linux-gnu "12.4.0"
      ;;
    ps3)
      _install_ps_platform ps3
      _install_cross_gcc_target powerpc64-linux-gnu "12.4.0"
      ;;
    ps4)
      _install_ps_platform ps4
      ;;
    ps5)
      _install_ps_platform ps5
      ;;
    gcc)
      _install_host_gcc ;;
    binutils)
      _install_binutils ;;
    *)
      _red "unknown platform: $id"
      return 1
      ;;
  esac
}

cmd_autoinstall() {
  local target="${1:-all}"
  banner
  _bold "catsdk autoinstall · ${CATSDK_TAG}"
  echo ""
  set +e
  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"
  case "$target" in
    all)
      _autoinstall_everything
      ;;
    programs|progs)
      _detect_host
      _detect_report
      _ensure_build_deps || true
      _ensure_dirs
      _path_prepend "${CATSDK_ROOT}/bin"
      echo ""
      _autoinstall_programs
      echo ""
      _probe_programs_report
      _print_shell_setup
      ;;
    *)
      _detect_host
      _path_prepend "${CATSDK_ROOT}/bin"
      _autoinstall_platform "$target"
      _install_tool_aliases || true
      _print_shell_setup
      ;;
  esac
  set -e
}

cmd_binutils_help() {
  cat <<'BH'
GNU binutils — there is no program named "binutils".
Use these commands instead:
  as       GNU assembler
  ld       GNU linker
  objcopy  object copy
  objdump  object dump
  ar       archive tool

6502 Atari:  cc65  ca65  ld65  dasm
Typo fix:    ld65 (not lda65) · gas aliases to as
BH
  for t in as ld objcopy objdump ar cc65 ca65 ld65 dasm; do
    _has_compiler "$t" && printf '  [ok] %s\n' "$t" || printf '  [--] %s\n' "$t"
  done
}

cmd_autoinstall_all() { cmd_autoinstall all; }

_platform_desc() {
  case "$1" in
    atari2600)    echo "Atari 2600 · dasm/cc65/batari" ;;
    atari5200)    echo "Atari 5200 · cc65/MAC65" ;;
    atari7800)    echo "Atari 7800 · cc65/7800basic" ;;
    atari8)       echo "Atari 8-bit · cc65/MAC65/GCC-6502" ;;
    atarist)      echo "Atari ST · Alcyon/m68k-elf-gcc" ;;
    atarilynx)    echo "Atari Lynx · cc65/GGP" ;;
    atarijaguar)  echo "Atari Jaguar · GASM/Alcyon" ;;
    atarifalcon)  echo "Atari Falcon · Pure C/m68k-gcc" ;;
    ps1)          echo "PlayStation 1 · catalog only (no compiler autoinstall)" ;;
    ps2)          echo "PlayStation 2 · EE-GCC/MIPS" ;;
    ps3)          echo "PlayStation 3 · Cell PPU/SPU GCC" ;;
    ps4)          echo "PlayStation 4 · orbis-clang (DevNet)" ;;
    ps5)          echo "PlayStation 5 · prospero-clang (DevNet)" ;;
    gcc)          echo "Host GCC · wget ftp.gnu.org" ;;
    cc65)         echo "cc65 · wget sourceforge" ;;
    binutils)     echo "GNU binutils · wget ftp.gnu.org" ;;
    dasm)         echo "dasm · 6502 macro assembler · sourceforge" ;;
    asm)          echo "All ASM · cc65+ca65+ld65 · dasm · binutils · gcc" ;;
    *)            echo "Platform: $1" ;;
  esac
}

_emit_gcc_wget() {
  local ver="${1:-14.2.0}" out=""
  out=$(printf '%s\n' "$(_embedded_mirrors)" | awk -F'|' -v ver="$ver" '$1=="gcc" && $2==ver {print $3; exit}')
  if [ -n "$out" ]; then
    echo "$out"
  else
    printf '%s\n' "$(_embedded_mirrors)" | awk -F'|' '$1=="gcc" {print $3; exit}'
  fi
}

_emit_cc65_wget() {
  local ver="${1:-2.19}" out=""
  out=$(printf '%s\n' "$(_embedded_mirrors)" | awk -F'|' -v ver="$ver" '$1=="cc65" && $2==ver {print $3; exit}')
  [ -n "$out" ] && echo "$out" || echo "cc65 URL embedded in catsdk.sh (_embedded_mirrors)"
}

_emit_dasm_wget() {
  local ver="${1:-2.20.14}" out=""
  out=$(printf '%s\n' "$(_embedded_mirrors)" | awk -F'|' -v ver="$ver" '$1=="dasm" && $2==ver {print $3; exit}')
  [ -n "$out" ] && echo "$out" || echo "dasm URL embedded in catsdk.sh (_embedded_mirrors)"
}

_emit_platform_env() {
  case "$1" in
    atari2600|atari8|atari5200|atari7800|atarilynx)
      echo 'export CC=cc65 CA65=ca65 LD65=ld65 DASM=dasm CATSDK_6502=1' ;;
    atarist|atarijaguar|atarifalcon) echo 'export CC=${CC:-m68k-elf-gcc} CATSDK_M68K=1' ;;
    ps2) echo 'export CC=${CC:-mipsel-linux-gnu-gcc} CATSDK_PS2=1' ;;
    ps3) echo 'export CC=${CC:-powerpc64-linux-gnu-gcc} CATSDK_CELL=1' ;;
    ps4) echo 'export SCE_ORBIS_SDK_DIR=${SCE_ORBIS_SDK_DIR:-}' ;;
    ps5) echo 'export SCE_PROSPERO_SDK_DIR=${SCE_PROSPERO_SDK_DIR:-}' ;;
    gcc) echo 'export CC=${CC:-gcc} CXX=${CXX:-g++}' ;;
    cc65) echo 'export CC=cc65 CA65=ca65 LD65=ld65 DASM=dasm' ;;
    dasm) echo 'export DASM=dasm' ;;
    asm) echo 'export CC=cc65 CA65=ca65 LD65=ld65 DASM=dasm' ;;
    binutils) echo 'export PATH=${PATH}' ;;
  esac
}

_embedded_pack_compilers() {
  local plat="$1"
  printf '%s\n' "$(_embedded_atari_ps5)" | while IFS='|' read -r p comp cpu year notes; do
    [ "$p" = "$plat" ] && printf '  %-22s %-8s %s  %s\n' "$comp" "$cpu" "$year" "$notes"
  done
}

embedded_platform_pack() {
  local id="$1"
  echo "════════════════════════════════════════════════════════"
  echo " catsdk ${CATSDK_VERSION} · ${id} · ${CATSDK_TAG}"
  echo " source: ${CATSDK_FILE##*/} (this file only)"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "[ platform ]"
  _platform_desc "$id"
  echo ""
  echo "[ compilers in this file — Atari→PS5 catalog ]"
  _embedded_pack_compilers "$id" || echo "  (see general gcc/cc65 entries)"
  echo ""
  echo "[ wget URL embedded in this file ]"
  case "$id" in
    atari2600|atari5200|atari7800|atari8|atarilynx|cc65|asm)
      _emit_cc65_wget "2.19"
      _emit_dasm_wget "2.20.14"
      ;;
    dasm) _emit_dasm_wget "2.20.14" ;;
    atarist|atarijaguar|atarifalcon|ps1|ps2|ps3|gcc) _emit_gcc_wget "14.2.0" ;;
    ps4|ps5) echo "  Sony DevNet SDK path — set in shell (not a file in catsdk)" ;;
    binutils)
      printf '%s\n' "$(_embedded_mirrors)" | while IFS='|' read -r pkg v url; do
        [ "$pkg" = "binutils" ] && echo "  $url"
      done
      ;;
  esac
  echo ""
  echo "[ env — in-memory ]"
  _emit_platform_env "$id"
  echo ""
  echo "[ sample hello — embedded in this file ]"
  _embedded_sample "$id"
}

recipe_platform() { embedded_platform_pack "$1"; }

wget_gcc() {
  local ver="${1:-14.2.0}"
  banner
  _bold "GCC ${ver} URL (embedded in ${CATSDK_FILE##*/})"
  echo ""
  _emit_gcc_wget "$ver"
}

cmd_mirrors() {
  if [ "${1:-}" = "test" ]; then
    cmd_mirrors_test "${2:-dasm}" "${3:-2.20.14}"
    return
  fi
  banner
  _bold "Embedded wget URLs · ${CATSDK_TAG}"
  echo ""
  printf '  %-10s %-8s  %s\n' "PKG" "VER" "URL"
  printf '%s\n' "$(_embedded_mirrors)" | while IFS='|' read -r pkg v url; do
    [ -z "${pkg:-}" ] && continue
    printf '  %-10s %-8s  %s\n' "$pkg" "$v" "$url"
  done
  echo ""
  _yellow "  test mirrors: catsdk.sh mirrors test [pkg] [ver]"
}

cmd_mirrors_test() {
  local pkg="${1:-dasm}" ver="${2:-2.20.14}"
  banner
  _bold "mirror test · ${pkg} ${ver}"
  _ensure_dirs
  local url tmp ok=0 fail=0
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    tmp="${CATSDK_SRC}/.mirror-test-$(basename "${url%%\?*}")"
    rm -f "$tmp"
    printf '  %-6s ' ""
    if _fetch "$url" "$tmp"; then
      _green "ok  ${url}"
      ok=$((ok + 1))
      rm -f "$tmp"
    else
      _red "fail ${url}"
      fail=$((fail + 1))
      rm -f "$tmp"
    fi
  done < <(_mirror_urls "$pkg" "$ver")
  echo ""
  printf '  result: %s ok  %s failed\n' "$ok" "$fail"
  [ "$fail" -eq 0 ]
}

cmd_this_file() {
  banner
  _bold "FILES = OFF · everything lives in this file"
  echo ""
  printf '  %-24s %s\n' "script" "${CATSDK_FILE}"
  printf '  %-24s %s\n' "version" "${CATSDK_VERSION} toolkit"
  printf '  %-24s %s\n' "files" "${FILES}"
  echo ""
  _bold "Embedded sections (heredocs in catsdk.sh)"
  printf '  %-28s %s\n' "_embedded_mirrors" "wget URL table"
  printf '  %-28s %s\n' "_embedded_atari_ps5" "Atari→PS5 compilers"
  printf '  %-28s %s\n' "_embedded_gcc" "GCC 1930–2026"
  printf '  %-28s %s\n' "_embedded_general" "language compilers"
  printf '  %-28s %s\n' "_embedded_asm_tools" "ASM tool catalog"
  printf '  %-28s %s\n' "_embedded_sample" "hello sources per platform"
  echo ""
  _bold "FILES = OFF · catalogs in this file · toolchains in CATSDK_PREFIX"
}

cmd_install() {
  local target="" apply=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --apply) apply=1 ;;
      *) target="$1" ;;
    esac
    shift
  done
  [ -n "$target" ] || { _red "Usage: catsdk.sh install <platform> [--apply]"; exit 1; }
  if [ "$apply" -eq 1 ]; then
    cmd_autoinstall "$target"
    return
  fi
  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"
  case "$target" in
    atari2600|atari5200|atari7800|atari8|atarilynx|atarist|atarijaguar|atarifalcon)
      embedded_platform_pack "$target" ;;
    ps1|ps2|ps3|ps4|ps5|gcc|cc65|dasm|binutils|asm)
      embedded_platform_pack "$target" ;;
    *)
      _red "Unknown: $target"
      exit 1 ;;
  esac
}

ATARI_PS5_CHAIN=(
  atari2600 atari5200 atari7800 atari8
  atarist atarilynx atarijaguar atarifalcon
  ps2 ps3 ps4 ps5
  cc65 gcc binutils dasm asm
)

cmd_install_all() {
  if [ "${1:-}" = "--apply" ]; then
    cmd_autoinstall all
    return
  fi
  banner
  _bold "All Atari → PS5 packs · embedded in ${CATSDK_FILE##*/}"
  echo "  (add --apply to wget+build all toolchains)"
  echo ""
  local p
  for p in "${ATARI_PS5_CHAIN[@]}"; do
    embedded_platform_pack "$p"
    echo ""
  done
}

cmd_list_asm() {
  banner
  _bold "ASM toolchains · ${CATSDK_TAG}"
  echo ""
  printf '  %-16s %-28s %-8s  %s\n' "TOOL" "ROLE" "INSTALL" "NOTES"
  printf '%s\n' "$(_embedded_asm_tools)" | while IFS='|' read -r tool role inst plats notes; do
    [ -z "${tool:-}" ] && continue
    local st="[--]"
    _has_compiler "$tool" && st="[ok]"
    printf '  %-16s %-28s %-8s  %s %s\n' "$tool" "$role" "$inst" "$st" "$notes"
  done
  echo ""
  _bold "autoinstall"
  echo "  ./catsdk.sh autoinstall cc65"
  echo "  ./catsdk.sh autoinstall dasm"
  echo "  ./catsdk.sh autoinstall asm"
  echo "  ./catsdk.sh autoinstall atari2600"
}

cmd_list_chain() {
  banner
  _bold "Atari → PS5 — every compiler (${CATSDK_TAG})"
  echo ""
  printf '  %-14s %-22s %-8s %-6s  %s\n' "PLATFORM" "COMPILER" "CPU" "YEAR" "NOTES"
  printf '%s\n' "$(_embedded_atari_ps5)" | while IFS='|' read -r plat comp cpu year notes; do
    [ -z "${plat:-}" ] && continue
    printf '  %-14s %-22s %-8s %-6s  %s\n' "$plat" "$comp" "$cpu" "$year" "$notes"
  done
}

cmd_list_gcc() {
  local filter="${1:-}"
  banner
  _bold "GCC compilers 1930–2026 (wget from ftp.gnu.org · no GitHub)"
  echo ""
  printf '%s\n' "$(_embedded_gcc)" | while IFS='|' read -r year ver notes; do
    [ -z "${year:-}" ] && continue
    if [ -n "$filter" ]; then
      [[ "$year" == "$filter"* || "$ver" == *"$filter"* ]] || continue
    fi
    printf '  %s  %-12s  %s\n' "$year" "$ver" "$notes"
  done
}

cmd_list() {
  local filter="${1:-}"
  banner
  _bold "All compilers 1930–2026 + Atari→PS5 (${CATSDK_TAG})"
  echo ""
  _bold "[ General languages ]"
  printf '%s\n' "$(_embedded_general)" | while IFS='|' read -r year name lang plat notes; do
    [ -z "${year:-}" ] && continue
    if [ -n "$filter" ]; then
      echo "$year $name $lang $plat $notes" | grep -qi "$filter" || continue
    fi
    printf '  %s  %-18s  %-8s  %s\n' "$year" "$name" "$lang" "$notes"
  done
  echo ""
  _bold "[ GCC 1930–2026 ]"
  printf '%s\n' "$(_embedded_gcc)" | while IFS='|' read -r year ver notes; do
    [ -z "${year:-}" ] && continue
    if [ -n "$filter" ]; then
      echo "$year $ver $notes" | grep -qi "$filter" || continue
    fi
    printf '  %s  %-12s  %s\n' "$year" "$ver" "$notes"
  done
  echo ""
  _bold "[ Atari → PS5 — all compilers ]"
  printf '%s\n' "$(_embedded_atari_ps5)" | while IFS='|' read -r plat comp cpu year notes; do
    [ -z "${plat:-}" ] && continue
    if [ -n "$filter" ]; then
      echo "$plat $comp $cpu $year $notes" | grep -qi "$filter" || continue
    fi
    printf '  %-14s %-22s %-8s %-6s  %s\n' "$plat" "$comp" "$cpu" "$year" "$notes"
  done
}

cmd_search() {
  local term="${1:-}"
  [ -n "$term" ] || { _red "Usage: catsdk.sh search <term>"; exit 1; }
  cmd_list "$term"
}

cmd_platforms() {
  banner
  _bold "catsdk 1.0 toolkit — install targets"
  echo ""
  for p in "${ATARI_PS5_CHAIN[@]}"; do
    printf '  %-14s %s\n' "$p" "$(_platform_desc "$p")"
  done
}

cmd_doctor() {
  banner
  _bold "catsdk 1.0 doctor · ${CATSDK_TAG}"
  echo ""
  printf '  %-20s %s\n' "version" "${CATSDK_VERSION} toolkit"
  printf '  %-20s %s\n' "files" "${FILES}"
  printf '  %-20s %s\n' "mode" "IN THIS FILE + autoinstall"
  printf '  %-20s %s\n' "prefix" "${CATSDK_PREFIX}"
  printf '  %-20s %s\n' "sdk disk reads" "none (catalog in-file)"
  echo ""
  _bold "Embedded catalog (this file only)"
  local n_atari n_gcc n_gen n_mir
  n_atari=$(printf '%s\n' "$(_embedded_atari_ps5)" | grep -c '|' || echo 0)
  n_gcc=$(printf '%s\n' "$(_embedded_gcc)" | grep -c '|' || echo 0)
  n_gen=$(printf '%s\n' "$(_embedded_general)" | grep -c '|' || echo 0)
  n_mir=$(printf '%s\n' "$(_embedded_mirrors)" | grep -c '|' || echo 0)
  printf '  %-20s %s entries\n' "Atari→PS5" "$n_atari"
  printf '  %-20s %s entries\n' "GCC 1930-2026" "$n_gcc"
  printf '  %-20s %s entries\n' "Languages" "$n_gen"
  printf '  %-20s %s URLs\n' "Mirrors" "$n_mir"
  echo ""
  _detect_host
  _detect_report
  _bold "compiler probe"
  printf '  %-14s %s\n' "6502" "cc65 ca65 ld65 dasm"
  printf '  %-14s %s\n' "GNU asm" "as ld (type: binutils for help)"
  printf '  %-14s %s\n' "tools bin" "${CATSDK_ROOT}/bin"
  echo ""
  if [ -d "$CATSDK_SRC" ]; then
    _bold "src cache"
    local bad=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      bad=1
      _yellow "  bad cache: ${f##*/} ($(wc -c <"$f" | tr -d ' ') bytes)"
    done < <(find "$CATSDK_SRC" -maxdepth 1 -type f \( -name '*.tar.*' -o -name '*.tgz' \) ! -size +1k 2>/dev/null)
    [ "$bad" -eq 0 ] && _green "  no corrupt zero-byte tarballs"
    echo ""
  fi
  _install_tool_aliases 2>/dev/null || true
  local probes=(cc65 ca65 ld65 dasm as ld gas binutils m68k-elf-gcc \
    mipsel-linux-gnu-gcc powerpc64-linux-gnu-gcc \
    orbis-clang prospero-clang gcc g++ clang wget make)
  for b in "${probes[@]}"; do
    if _has_compiler "$b"; then printf '  [ok] %s\n' "$b"
    else printf '  [--] %s\n' "$b"; fi
  done
  echo ""
  [ -x "${SCE_PROSPERO_SDK_DIR:-}/host_tools/bin/prospero-clang" ] && \
    _green "  PS5 prospero-clang found" || _yellow "  PS5: set SCE_PROSPERO_SDK_DIR"
  [ -x "${SCE_ORBIS_SDK_DIR:-}/host_tools/bin/orbis-clang" ] && \
    _green "  PS4 orbis-clang found" || _yellow "  PS4: set SCE_ORBIS_SDK_DIR"
}

cmd_env() {
  if [ "${1:-}" = "--prefix" ]; then
    _ensure_dirs
    _install_tool_aliases 2>/dev/null || true
    _ensure_ps_dirs 2>/dev/null || true
    echo "export CATSDK_PREFIX=\"${CATSDK_PREFIX}\""
    echo "export CATSDK_ROOT=\"${CATSDK_ROOT}\""
    echo "export CATSDK_PS=\"${CATSDK_PS}\""
    echo "export CATSDK_FILES=\"off\""
    echo "export PS2SDK=\"${PS2SDK}\""
    echo "export PS3SDK=\"${PS3SDK}\""
    echo "export PS4SDK=\"${PS4SDK}\""
    echo "export PS5SDK=\"${PS5SDK}\""
    echo "export PATH=\"${CATSDK_ROOT}/bin:${PS2SDK}/bin:${PS3SDK}/bin:${PS4SDK}/bin:${PS5SDK}/bin:\$PATH\""
    echo "# 6502 only — do not set CC=cc65 globally if you also build cross-GCC:"
    echo "export CATSDK_6502_CC=\"\${CATSDK_6502_CC:-cc65}\""
    echo "export CA65=\"\${CA65:-ca65}\""
    echo "export LD65=\"\${LD65:-ld65}\""
    echo "export DASM=\"\${DASM:-dasm}\""
    echo "export SCE_ORBIS_SDK_DIR=\"\${SCE_ORBIS_SDK_DIR:-}\""
    echo "export SCE_PROSPERO_SDK_DIR=\"\${SCE_PROSPERO_SDK_DIR:-}\""
    return
  fi
  cat <<ENV
# catsdk 1.0 toolkit · FILES = OFF · IN THIS FILE
export CATSDK_VERSION="1.0"
export CATSDK_FILES="off"
export CATSDK_NAME="catsdk"
export CATSDK_MODE="in-this-file-only"
export CATSDK_PREFIX="${CATSDK_PREFIX}"
export CATSDK_ROOT="${CATSDK_ROOT}"
export PATH="${CATSDK_ROOT}/bin:\$PATH"
ENV
}

cmd_version() {
  ascii_banner
  echo "catsdk ${CATSDK_VERSION} toolkit · IN THIS FILE · gcc 1930-2026 · ${CATSDK_TAG}"
}

main() {
  case "${1:-}" in
    help|-h|--help) usage ;;
    version|-v|--version) cmd_version ;;
    list|ls) shift; cmd_list "${1:-}" ;;
    list-gcc) shift; cmd_list_gcc "${1:-}" ;;
    list-chain|chain) cmd_list_chain ;;
    list-asm|asm-list) cmd_list_asm ;;
    search|find) shift; cmd_search "${1:-}" ;;
    platforms|targets) cmd_platforms ;;
    install) shift; cmd_install "$@" ;;
    install-all|install-chain|all)
      shift
      if [ "${1:-}" = "--apply" ]; then
        cmd_autoinstall all
      else
        cmd_install_all "${1:-}"
      fi
      ;;
    autoinstall|auto-install|setup)
      shift
      cmd_autoinstall "${1:-all}"
      ;;
    autoinstall-all) cmd_autoinstall all ;;
    programs|progs) cmd_autoinstall programs ;;
    import) shift; cmd_import "${1:-playstation}" ;;
    wget-gcc) shift; wget_gcc "${1:-14.2.0}" ;;
    mirrors|urls) shift; cmd_mirrors "$@" ;;
    this-file|thisfile|file) cmd_this_file ;;
    doctor|check) cmd_doctor ;;
    binutils|gas|gasm|tools) cmd_binutils_help ;;
    env|shell) shift; cmd_env "${1:-}" ;;
    sample|demo) shift; cmd_sample "${1:-gcc}" ;;
    banner) banner ;;
    "")
      cmd_autoinstall all
      ;;
    *)
      _red "Unknown: $1"
      usage
      exit 1
      ;;
  esac
}

# Run immediately — no command required · FILES = OFF · catalogs in this file
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
