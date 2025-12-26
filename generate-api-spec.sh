#!/bin/bash

mix openapi.spec.json --spec MtgFriendsWeb.ApiSpec --filename mobile/src/api/generated/openapi.json

cd mobile

npm run generate:api