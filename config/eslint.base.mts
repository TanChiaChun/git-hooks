import perfectionist from 'eslint-plugin-perfectionist'
import { defineConfig } from 'eslint/config'
import tseslint from 'typescript-eslint'

export default defineConfig([
  tseslint.configs.recommended,
  perfectionist.configs['recommended-alphabetical'],
  {
    rules: {
      '@typescript-eslint/explicit-function-return-type': 'error',
    },
  },
])
