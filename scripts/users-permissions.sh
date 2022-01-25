#!/usr/bin/env bash

USER="admin:pass"
HEADER="Content-Type: application/json"

# Alias for curl
curl="./bin/curl -u ${USER}"

# Create "Teacher" team and store its ID
TEACHER_TEAM_ID=$(${curl} -d "name=Teacher" grafana:3000/api/teams | jq '.teamId')

# Create "student" and "teacher" users
STUDENT_USER_ID=$(${curl} -d "email=student@example.org&login=student&password=funfunfun" grafana:3000/api/admin/users | jq '.id')
TEACHER_USER_ID=$(${curl} -d "email=teacher@example.org&login=teacher&password=funfunfun" grafana:3000/api/admin/users | jq '.id')

# Return id of the "teacher" folder
VIDEO_FOLDER_UID=$(${curl} "http://grafana:3000/api/folders" | jq -r '.[] | select(.title=="teachers") | .uid')

# Get permission on "teacher" folder for the "Teacher team"
DATA="{\"items\":[{\"role\":\"Viewer\",\"permission\":1},{\"teamId\":${TEACHER_TEAM_ID},\"permission\":1}]}"
${curl} -H "${HEADER}" -d "${DATA}" "http://grafana:3000/api/folders/${VIDEO_FOLDER_UID}/permissions"

# Add "teacher" user to the "Teacher" team
${curl} -H "${HEADER}" -d "{\"userId\": ${TEACHER_USER_ID}}" grafana:3000/api/teams/"${TEACHER_TEAM_ID}"/members
