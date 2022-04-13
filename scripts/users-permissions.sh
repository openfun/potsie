#!/usr/bin/env sh

set -eo pipefail

BASE_URL="${GRAFANA_BASE_URL:-http://grafana:3000}"
ADMIN_USERNAME="${GRAFANA_ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-pass}"
ADMIN_USER="${ADMIN_USERNAME}:${ADMIN_PASSWORD}"
TEACHER_USERNAME="${GRAFANA_TEACHER_USERNAME:-teacher}"
TEACHER_EMAIL="${GRAFANA_TEACHER_EMAIL:-teacher@example.org}"
TEACHER_PASSWORD="${GRAFANA_TEACHER_PASSWORD:-funfunfun}"
TEACHER_TEAM="Teacher"
TEACHER_FOLDER="teachers"

CURL() {
    curl -s -u "${ADMIN_USER}" -H "Content-Type: application/json" "$@"
}

# Create "Teacher" team if not exist and store its ID
TEACHER_TEAM_ID=$(
    CURL \
        "${BASE_URL}/api/teams/search?name=${TEACHER_TEAM}" |
    jq -r '.teams[0].id'
)

to_json() {
    echo "$*" | tr "'" "\""
}

if [ "${TEACHER_TEAM_ID}" = "null" ]; then
    payload=$(to_json "{'name': '${TEACHER_TEAM}'}")
    TEACHER_TEAM_ID=$(
        CURL \
            -d "${payload}" \
            "${BASE_URL}/api/teams" |
        jq '.teamId'
    )
fi

# Create "teacher" user if not exist
TEACHER_USER_ID=$(
    CURL \
        "${BASE_URL}/api/users/lookup?loginOrEmail=${TEACHER_USERNAME}" |
    jq '.id'
)

if [ "${TEACHER_USER_ID}" = "null" ]; then

    payload=$(to_json "{
        'email': '${TEACHER_EMAIL}',
        'login': '${TEACHER_USERNAME}',
        'password': '${TEACHER_PASSWORD}'
    }")
    TEACHER_USER_ID=$(
        CURL \
            -d "${payload}" \
            "${BASE_URL}/api/admin/users" |
        jq '.id'
    )
fi

# Add "teacher" user to the "Teacher" team
payload=$(to_json "{
    'userId': ${TEACHER_USER_ID}
}")
CURL \
    -d "${payload}" \
    "${BASE_URL}/api/teams/${TEACHER_TEAM_ID}/members"

# Return id of the folders
TEACHER_FOLDER_UID=$(
    CURL \
        "${BASE_URL}/api/folders" |
    jq -r ".[] | select(.title==\"${TEACHER_FOLDER}\") | .uid"
)

# Get "Viewer" permission on "teacher" folder for the "Teacher" team only
payload=$(to_json "{
    'items': [
        {
            'teamId': ${TEACHER_TEAM_ID},
            'permission': 1
        }
    ]
}")
CURL \
    -d "${payload}" \
    "${BASE_URL}/api/folders/${TEACHER_FOLDER_UID}/permissions"
