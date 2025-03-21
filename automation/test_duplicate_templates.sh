#!/bin/bash
#
# This file is part of the KubeVirt project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright 2019 Red Hat, Inc.
#
set -ex

# Any template can be used here as they all have the same version label, fedora is an arbitrary one
ver_label=$( \
  yq -o props '.metadata.labels | with_entries(select(.key == "template.kubevirt.io/version"))' \
  dist/templates/fedora-server-large.yaml \
)

templates=(dist/templates/*.yaml)

for template in "${templates[@]}"; do
  readarray -t template_oss < <( \
    yq -o props '.metadata.labels | with_entries(select(.key == "os.template.kubevirt.io/*"))' "$template" \
  )

  readarray -t template_workloads < <( \
    yq -o props '.metadata.labels | with_entries(select(.key == "workload.template.kubevirt.io/*"))' "$template" \
  )

  readarray -t template_flavors < <( \
    yq -o props '.metadata.labels | with_entries(select(.key == "flavor.template.kubevirt.io/*"))' "$template" \
  )

  readarray -t template_archs < <( \
    yq -o props '.metadata.labels | with_entries(select(.key == "template.kubevirt.io/architecture"))' "$template" \
  )

  for os in "${template_oss[@]}"; do
    for workload in "${template_workloads[@]}"; do
      for flavor in "${template_flavors[@]}"; do
        for architecture in "${template_archs[@]}"; do
          count=$(oc get template -l "$os,$workload,$flavor,$ver_label,$architecture" --no-headers | wc -l)

          if [[ $count -ne 1 ]]; then
            echo "There are $count templates found with the following labels $os,$workload,$flavor,$ver_label,$architecture"
            exit 1
          fi
        done
      done
    done
  done
done
