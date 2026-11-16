import perfectionist from 'eslint-plugin-perfectionist'
import { defineConfig, globalIgnores } from 'eslint/config'
import tseslint from 'typescript-eslint'

export default defineConfig([
  // ESLint ignores node_modules and .git by default.
  globalIgnores(['.venv', 'git-hooks/']),

  tseslint.configs.recommended,
  perfectionist.configs['recommended-alphabetical'],
  {
    rules: {
      '@typescript-eslint/explicit-function-return-type': 'error',
    },
  },
])
