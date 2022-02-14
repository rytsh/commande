#!/usr/bin/env bash

#######################
# Build and Test script
#######################


S_BASE_DIR="$(realpath $(dirname "$0"))"
cd $S_BASE_DIR

S_PROGRAM_NAME="$(head -n 1 go.mod | cut -d' ' -f2 | rev | cut -d'/' -f1 | rev)"
S_MAIN_GO="./cmd/${S_PROGRAM_NAME}/main.go"
S_RES="./res"
S_ICON="icon.ico"

# variables form the environment
BUILD_OUTPUT=${OUTPUT_FOLDER:-"./out"}
BUILD_PLATFORMS=${BUILD_PLATFORMS:-"windows"}
BUILD_VERSION=${BUILD_VERSION:-$(git describe --tags --first-parent --match "v[0-9]*" 2> /dev/null || echo v0.0.0)}

# flags
PKG=$(head -n 1 go.mod | cut -d' ' -f2)
FLAG=(
"${PKG}/internal/conf.AppName=${S_PROGRAM_NAME}"
"${PKG}/internal/conf.AppVersion=${BUILD_VERSION}"
)

# internal variables
S_SUPPORTED_PLATFORMS="windows"

# version fix
S_BUILD_VERSION="${BUILD_VERSION/v/}"
S_VERSION_MAJOR="$(echo ${BUILD_VERSION/v/} | cut -d'.' -f1)"
S_VERSION_MINOR="$(echo ${BUILD_VERSION/v/} | cut -d'.' -f2)"
S_VERSION_PATCH="$(echo ${BUILD_VERSION/v/} | cut -d'.' -f3 | cut -d'-' -f1)"
S_VERSION_BUILD="$(echo ${BUILD_VERSION/v/} | cut -d'.' -f3 | cut -d'-' -f2 -s)"
S_VERSION_BUILD="${S_VERSION_BUILD:-0}"

S_VERSION="$S_VERSION_MAJOR.$S_VERSION_MINOR.$S_VERSION_PATCH.$S_VERSION_BUILD"

function usage() {
  cat - <<EOF
Build Project
Usage: $0 <OPTIONS>

OPTIONS:
  --platforms
    Define the platforms to build.
    Platforms: ${S_SUPPORTED_PLATFORMS}
    Default: \${BUILD_PLATFORMS} or windows
  --build
    Specify the dockerfile to build.

  -h, --help
    This help page
EOF
}

# parse the command line arguments
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  --platforms )
    BUILD_PLATFORMS="$2"
    shift 1
    ;;
  --build)
    S_BUILD="Y"
    ;;
  --generate-syso)
    S_GENERATE_SYSO="Y"
    ;;
  -h | --help )
    usage
    exit
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
esac; shift 1; done
if [[ "$1" == '--' ]]; then shift; fi

############################# FUNCTIONS
function generate_syso() {
  echo "==> Generating syso file"

  cat > $(dirname ${S_MAIN_GO})/${S_PROGRAM_NAME}.rc << EOL
id ICON "../../${S_RES}/${S_ICON}"
GLFW_ICON ICON "../../${S_RES}/${S_ICON}"
EOL

  x86_64-w64-mingw32-windres $(dirname ${S_MAIN_GO})/${S_PROGRAM_NAME}.rc -O coff -o $(dirname ${S_MAIN_GO})/${S_PROGRAM_NAME}.syso

  if [[ ! $(command -v goversioninfo) ]]; then
    go install github.com/josephspurrier/goversioninfo/cmd/goversioninfo
  fi

  # generate the version info
  export S_VERSION_MAJOR S_VERSION_MINOR S_VERSION_PATCH S_VERSION_BUILD S_VERSION
  envsubst '$S_VERSION_MAJOR,$S_VERSION_MINOR,$S_VERSION_PATCH,$S_VERSION_BUILD,$S_VERSION' < ${S_RES}/versioninfo.json.tmp > ${S_RES}/versioninfo.json
  envsubst '$S_VERSION' < ${S_RES}/${S_PROGRAM_NAME}.exe.manifest.tmp > ${S_RES}/${S_PROGRAM_NAME}.exe.manifest

  # go generate ${S_MAIN_GO}
  goversioninfo -64 -manifest=./res/${S_PROGRAM_NAME}.exe.manifest -o $(dirname ${S_MAIN_GO})/resource.syso ./res/versioninfo.json
}

function build_windows() {
  # 1: output file name
  # 2: go file to build
  # 3: output folder
  # 4: res folder

  go generate ${2}

  # install mingw-w64
  GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ HOST=x86_64-w64-mingw32 \
    go build -trimpath -ldflags "-s -w -H=windowsgui -extldflags=-static" -v -o ${3}/${1}.exe $(dirname ${2})
}
############################# END FUNCTIONS

############################# PROCESS
if [[ "$S_GENERATE_SYSO" == "Y" ]]; then
  generate_syso
fi

if [[ ${S_BUILD} == "Y" ]]; then
  echo "==> Building platforms ${BUILD_PLATFORMS}"
  mkdir -p ${BUILD_OUTPUT}
  IFS=',' read -ra S_PLATFORMS_ARR <<< $(echo ${BUILD_PLATFORMS} | tr -d ' ')
  for S_PLATFORM in "${S_PLATFORMS_ARR[@]}"; do
    echo "==> Started build for ${S_PLATFORM}"
    case "$S_PLATFORM" in
      windows)
        build_windows ${S_PROGRAM_NAME} ${S_MAIN_GO} ${BUILD_OUTPUT} ${S_RES}
        ;;
      *)
        echo "cannot find ${S_PLATFORM}: supported platforms are: ${S_SUPPORTED_PLATFORMS}"
        ;;
    esac
  done
fi
############################# END PROCESS
