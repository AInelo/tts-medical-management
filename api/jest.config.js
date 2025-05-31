/** @type {import('ts-jest').JestConfigWithTsJest} */
export default {
    preset: "ts-jest",
    testEnvironment: "node",
    roots: ["<rootDir>/src"],
    transform: {
      "^.+\\.ts?$": "ts-jest",
    },
    moduleFileExtensions: ["ts", "tsx", "js"],
    testMatch: ["**/__tests__/**/*.test.ts"],
  };
  
  