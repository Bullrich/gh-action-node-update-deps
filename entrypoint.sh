#!/bin/bash
set -eu

GIT_USER_NAME=${1}
GIT_USER_EMAIL=${2}
PRE_COMMIT_SCRIPT=${3}
PULL_REQUEST_LABELS=${4}
COMMIT_MSG_PREFIX=${5}
NPM_SCOPE=${6}
NPM_REGISTRY=${7}
REQUESTED_USER=${8}
REQUESTED_TEAM=${9}

export GITHUB_HOST=${GITHUB_SERVER_URL}

if [ -n "${NPM_SCOPE}" ] && [ -n "${NPM_REGISTRY}" ]; then
  NPM_REGISTRY_PATH=${NPM_REGISTRY#https:}

  echo "${NPM_SCOPE}:registry=${NPM_REGISTRY}" > .npmrc
  echo "${NPM_REGISTRY_PATH}:_authToken=${NPM_TOKEN}" >> .npmrc
  echo "${NPM_REGISTRY_PATH}:always-auth=true" >> .npmrc
fi

npx update-by-scope ${NPM_SCOPE}

if $(git diff-index --quiet HEAD); then
  echo 'No dependencies needed to be updated!'
  exit 0
fi

RUN_LABEL="${GITHUB_WORKFLOW}@${GITHUB_RUN_NUMBER}"
RUN_ENDPOINT="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

COMMIT_MSG="${COMMIT_MSG_PREFIX}: update deps ($(date -I))"
PR_BRANCH=chore/deps-$(date +%s)

git config user.name ${GIT_USER_NAME}
git config user.email ${GIT_USER_EMAIL}
git checkout -b ${PR_BRANCH}

if [ -n "${PRE_COMMIT_SCRIPT}" ]; then
  ${PRE_COMMIT_SCRIPT}
fi

if [ -e .npmrc ]; then
  git checkout -- .npmrc
fi

git commit -am "${COMMIT_MSG}"
git config --global --add hub.host "${GITHUB_SERVER_URL}"
git push origin ${PR_BRANCH}

DEFAULT_BRANCH=$(curl --silent \
  --url ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY} \
  --header "authorization: Bearer ${GITHUB_TOKEN}" \
  --header 'content-type: application/json' \
  --fail | jq -r .default_branch)

git fetch origin ${DEFAULT_BRANCH}

echo "Server is ${GITHUB_SERVER_URL} and default branch is ${DEFAULT_BRANCH}"

PULL_URL=$(curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "authorization: Bearer ${GITHUB_TOKEN}" \
  ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls \
  -d "{\"head\":\"${PR_BRANCH}\",\"base\":\"${DEFAULT_BRANCH}\",\"title\":\"${COMMIT_MSG}\"}" \
  | jq -r '._links.self.href')

if [ -n "${REQUESTED_USER}" ] || [ -n "${REQUESTED_TEAM}" ]; then
  if [ -n "${REQUESTED_USER}" ];then
    REVIEWERS='"reviewers": ["'${REQUESTED_USER}'"]'
    if [ -n "${REQUESTED_TEAM}" ];then
        REVIEWERS="${REVIEWERS},"
    fi
  fi
  if [ -n "${REQUESTED_TEAM}" ];then
    REVIEWERS='{'${REVIEWERS}' "team_reviewers": ["'${REQUESTED_TEAM}'"]}'
  fi

  curl \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "authorization: Bearer ${GITHUB_TOKEN}" \
    ${PULL_URL}/requested_reviewers \
    -d $REVIEWERS
fi

echo "Created Pull Request!"
