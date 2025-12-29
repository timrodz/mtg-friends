---
trigger: glob
globs: *.js, *.jsx, *.ts, *.tsx
---

This is a mobile application built with TypeScript and React Native via Expo.

Rules

- Never do explicit type casts
- After editing a file, always cleanup unused imports and run the linter to fix those errors. If they seem too difficult, prompt the user about this
- To run the app, use `npx expo start`
- For dependencies such as `useEffect`, `useMemo`, `useCallback` please use primitives only, not objects, functions, or arrays
- Whenever you call the API client via hooks, the usage of `isLoading` must be factored into dependency arrays. Always return early if `isLoading` evaluates to true
- Always use descriptive variable names and avoid one-letter variables
