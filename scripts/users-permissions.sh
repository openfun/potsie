#!/usr/bin/env bash

set -oe pipefail

USER="admin:pass"
HEADER="Content-Type: application/json"

# Alias for curl
curl="./bin/curl -u ${USER}"

# Create "Teacher" and "Student" team if not exist and store its ID
TEACHER_TEAM_ID=$(${curl} -H "${HEADER}" "http://grafana:3000/api/teams/search?name=Teacher" | jq -r '.teams[0].id')
STUDENT_TEAM_ID=$(${curl} -H "${HEADER}" "http://grafana:3000/api/teams/search?name=Student" | jq -r '.teams[0].id')

if [[ $TEACHER_TEAM_ID == "null" ]]; then
    TEACHER_TEAM_ID=$(${curl} -d "name=Teacher" grafana:3000/api/teams | jq '.teamId')
fi

if [[ $STUDENT_TEAM_ID == "null" ]]; then
    STUDENT_TEAM_ID=$(${curl} -d "name=Student" grafana:3000/api/teams | jq '.teamId')
fi

# Create "student" and "teacher" users if not exist
STUDENT_USER_ID=$(${curl} -H "${HEADER}" "http://grafana:3000/api/users/lookup?loginOrEmail=student" | jq '.id')
TEACHER_USER_ID=$(${curl} -H "${HEADER}" "http://grafana:3000/api/users/lookup?loginOrEmail=teacher" | jq '.id')

if [[ $STUDENT_USER_ID == "null" ]]; then
    STUDENT_USER_ID=$(${curl} -d "email=student@example.org&login=student&password=funfunfun" grafana:3000/api/admin/users | jq '.id')
fi

if [[ $TEACHER_USER_ID == "null" ]]; then
    TEACHER_USER_ID=$(${curl} -d "email=teacher@example.org&login=teacher&password=funfunfun" grafana:3000/api/admin/users | jq '.id')
fi

# Add "teacher" user to the "Teacher" team
${curl} -H "${HEADER}" -d "{\"userId\": ${TEACHER_USER_ID}}" "http://grafana:3000/api/teams/${TEACHER_TEAM_ID}/members"

# Return id of the folders
TEACHER_FOLDER_UID=$(${curl} "http://grafana:3000/api/folders" | jq -r '.[] | select(.title=="teachers") | .uid')
PLATFORM_FOLDER_UID=$(${curl} "http://grafana:3000/api/folders" | jq -r '.[] | select(.title=="platform") | .uid')

# Get "Viewer" permission on "teacher" folder for the "Teacher" team only
TEACHER_FOLDER_PERMISSION="{\"items\":[{\"teamId\":${TEACHER_TEAM_ID},\"permission\":1}]}"
${curl} -H "${HEADER}" -d "${TEACHER_FOLDER_PERMISSION}" "http://grafana:3000/api/folders/${TEACHER_FOLDER_UID}/permissions"

# Remove permission for "Student" and "Teacher" teams on the "platform" folder
${curl} -H "${HEADER}" -d "{}" "http://grafana:3000/api/folders/${PLATFORM_FOLDER_UID}/permissions"
