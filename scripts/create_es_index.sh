#!/usr/bin/env bash

set -eo pipefail

# Usage: scripts/create_es_index.sh [INDEX]

# Defaults
declare -r INDEX="${1:-statements-fixtures}"

# Create the statements index with appropriate mapping
echo "Will create '${INDEX}' elasticsearch index..."

curl -X PUT "elasticsearch:9200/${INDEX}?pretty"
curl -X PUT "elasticsearch:9200/${INDEX}/_mapping?pretty" -H 'Content-Type: application/json' -d'
{
  "properties": {
    "verb.id": {
      "type": "keyword"
    },
    "object.id": {
      "type": "keyword"
    },
    "object.definition.type": {
      "type": "keyword"
    },
    "context.contextActivities.category.id": {
      "type": "keyword"
    },
    "context.contextActivities.parent.definition.type": {
      "type": "keyword"
    },
    "context.contextActivities.parent.id": {
      "type": "keyword"
    }
  }
}
'

