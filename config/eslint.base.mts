import { defineConfig } from "eslint/config";
import tseslint from 'typescript-eslint';

export default defineConfig([
  tseslint.configs.recommended,
  {
    rules: {
      "sort-imports": "error",
      "@typescript-eslint/explicit-function-return-type": "error",
    },
  },
]);
