#!/bin/bash
set -e

mix openapi.spec.json --spec MtgFriendsWeb.ApiSpec --filename mobile/src/api/generated/openapi.json

cd mobile || exit 1

npm run generate:api