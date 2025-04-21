#!/usr/bin/env bash

# Prerequisites
# - kubeseal 0.29.0

kubeseal_config=("--controller-name" "sealed-secrets" "--controller-namespace" "sealed-secrets")

find . -type f -name '*.secret.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Secret $file"
done

find . -type f -name '*.sealedsecret.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - SealedSecret $file"
    kubeseal "${kubeseal_config[@]}" --validate --secret-file "$file" --cert $PUBLICKEY
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      secret=$(echo "$file" | sed "s/sealedsecret/secret/")
      echo "INFO - Reseal invalid SealedSecret from Secret ${secret}"
      kubeseal "${kubeseal_config[@]}" --format yaml --cert $PUBLICKEY  -f "${secret}" -w ${file}
    fi
done
