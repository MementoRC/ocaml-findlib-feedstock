# Reusable helpers sourced by build.sh.

warn() {
  echo "WARNING: $*" >&2
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

try_or_warn() {
  local msg="${1}"
  shift
  "$@" 2>/dev/null || warn "${msg}"
}

try_or_fail() {
  local msg="${1}"
  shift
  "$@" || fail "${msg}"
}

is_cross_compile() { [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; }
is_macos() { [[ "${target_platform}" == "osx-"* ]]; }
is_linux() { [[ "${target_platform}" == "linux-"* ]]; }
build_is_macos() { [[ "${build_platform:-${target_platform}}" == "osx-"* ]]; }
