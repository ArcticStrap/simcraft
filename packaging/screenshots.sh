#!/usr/bin/env bash
# Generates reproducible native application screenshots for documentation.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/assets/screenshots"

echo "Capturing relay feedback limit cycle in SimCraft Studio..."
cargo run --bin simcraft-studio -- "$ROOT/examples/relay_feedback.simcraft" --select relay --screenshot "$ROOT/assets/screenshots/studio_relay_feedback.png"

echo "Capturing harmonic pendulum in SimCraft Studio..."
cargo run --bin simcraft-studio -- "$ROOT/examples/pendulum.simcraft" --select theta --screenshot "$ROOT/assets/screenshots/studio_pendulum.png"

echo "Screenshots saved to $ROOT/assets/screenshots/"
