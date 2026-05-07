#!/usr/bin/env bash

is_participant_index() {
  [[ "$1" =~ ^0*[1-9][0-9]*$ ]]
}

participant_number() {
  local raw="$1"
  echo "$((10#$raw))"
}

participant_id_for_index() {
  local index
  index="$(participant_number "$1")"
  printf "p%02d\n" "$index"
}

participant_port_for_index() {
  local raw="$1"
  local start_port="$2"
  local port_step="$3"
  local index
  index="$(participant_number "$raw")"
  echo "$((start_port + ((index - 1) * port_step)))"
}

validate_participant_id() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}
