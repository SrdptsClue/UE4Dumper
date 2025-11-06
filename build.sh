#!/usr/bin/env bash
set -euo pipefail

ABI="x86_64"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JNI_DIR="$PROJECT_ROOT/jni"
CLEAN=0
NDK_BUILD_BIN="${NDK_BUILD_BIN:-}"

usage() {
    cat <<'EOF'
Usage: ./build.sh [options]

Options:
  --ndk <path>    Absolute path to the ndk-build binary.
  --abi <name>    Override target ABI (default: x86_64).
  --clean         Remove intermediate build artifacts for the selected ABI.
  -h, --help      Show this help message.

The script expects a recent Android NDK installation. Set ANDROID_NDK_HOME,
ANDROID_NDK_ROOT, NDK_HOME, or NDK_ROOT if ndk-build is not on PATH.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ndk)
            shift
            [[ $# -gt 0 ]] || { echo "Missing argument for --ndk." >&2; exit 1; }
            NDK_BUILD_BIN="$1"
            ;;
        --abi)
            shift
            [[ $# -gt 0 ]] || { echo "Missing argument for --abi." >&2; exit 1; }
            ABI="$1"
            ;;
        --clean)
            CLEAN=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$NDK_BUILD_BIN" ]]; then
    if command -v ndk-build >/dev/null 2>&1; then
        NDK_BUILD_BIN="$(command -v ndk-build)"
    else
        for var in ANDROID_NDK_HOME ANDROID_NDK_ROOT NDK_HOME NDK_ROOT; do
            ndk_root="${!var:-}"
            if [[ -n "$ndk_root" && -x "$ndk_root/ndk-build" ]]; then
                NDK_BUILD_BIN="$ndk_root/ndk-build"
                break
            fi
        done
    fi
fi

if [[ -z "$NDK_BUILD_BIN" || ! -x "$NDK_BUILD_BIN" ]]; then
    echo "Unable to locate ndk-build. Use --ndk to provide the path or set an NDK_* environment variable." >&2
    exit 1
fi

BUILD_ARGS=(
    "NDK_PROJECT_PATH=$PROJECT_ROOT"
    "APP_BUILD_SCRIPT=$JNI_DIR/Android.mk"
    "NDK_APPLICATION_MK=$JNI_DIR/Application.mk"
    "APP_ABI=$ABI"
)

if [[ $CLEAN -eq 1 ]]; then
    BUILD_ARGS+=("clean")
fi

"$NDK_BUILD_BIN" "${BUILD_ARGS[@]}"

if [[ $CLEAN -eq 0 ]]; then
    echo "Build completed for ABI $ABI. Output binaries are under $PROJECT_ROOT/libs/$ABI/"
else
    echo "Clean completed for ABI $ABI."
fi
