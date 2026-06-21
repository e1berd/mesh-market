set shell := ["bash", "-uc"]

default:
    @just --list

setup:
    sudo apt update
    sudo apt install -y build-essential clang cmake ninja-build pkg-config \
        libgtk-3-dev liblzma-dev \
        curl file git unzip xz-utils zip libglu1-mesa

get:
    flutter pub get

analyze:
    dart analyze lib test

format:
    dart format lib test

test:
    dart test test/unit

run platform="linux":
    flutter run -d {{platform}}

build target="linux":
    flutter build {{target}}

clean:
    flutter clean
