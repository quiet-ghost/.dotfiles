import type { Plugin } from "@opencode-ai/plugin";

const PROVIDER_ID = "openai-api";
const PROVIDER_NAME = "OpenAI (API key)";
const PROVIDER_PACKAGE = "@ai-sdk/openai";

const OPENAI_MODELS = {
  "gpt-5.2": {
    name: "GPT-5.2",
    limit: { context: 200000, output: 65536 },
    cost: { input: 1.75, output: 14.0, cache_read: 0.175 },
  },
  "gpt-5.2-pro": {
    name: "GPT-5.2 Pro",
    limit: { context: 200000, output: 65536 },
    cost: { input: 21.0, output: 168.0 },
  },
  "gpt-5": {
    name: "GPT-5",
    limit: { context: 200000, output: 65536 },
    cost: { input: 3.0, output: 15.0, cache_read: 0.75 },
  },
  "gpt-5-pro": {
    name: "GPT-5 Pro",
    limit: { context: 200000, output: 65536 },
    cost: { input: 15.0, output: 75.0, cache_read: 3.75 },
  },
  "gpt-5-mini": {
    name: "GPT-5 Mini",
    limit: { context: 200000, output: 65536 },
    cost: { input: 0.25, output: 2.0, cache_read: 0.025 },
  },
  "gpt-5-nano": {
    name: "GPT-5 Nano",
    limit: { context: 200000, output: 65536 },
    cost: { input: 0.1, output: 0.4, cache_read: 0.01 },
  },
  "gpt-4.1": {
    name: "GPT-4.1",
    limit: { context: 1048576, output: 32768 },
    cost: { input: 3.0, output: 12.0, cache_read: 0.75 },
  },
  "gpt-4.1-mini": {
    name: "GPT-4.1 Mini",
    limit: { context: 1048576, output: 32768 },
    cost: { input: 0.8, output: 3.2, cache_read: 0.2 },
  },
  "gpt-4.1-nano": {
    name: "GPT-4.1 Nano",
    limit: { context: 1048576, output: 32768 },
    cost: { input: 0.2, output: 0.8, cache_read: 0.05 },
  },
  "gpt-4o": {
    name: "GPT-4o",
    limit: { context: 128000, output: 16384 },
    cost: { input: 2.5, output: 10.0, cache_read: 1.25 },
  },
  "gpt-4o-mini": {
    name: "GPT-4o Mini",
    limit: { context: 128000, output: 16384 },
    cost: { input: 0.15, output: 0.6, cache_read: 0.075 },
  },
  "o3": {
    name: "o3",
    limit: { context: 200000, output: 65536 },
    cost: { input: 5.0, output: 25.0, cache_read: 1.25 },
  },
  "o3-mini": {
    name: "o3 Mini",
    limit: { context: 200000, output: 65536 },
    cost: { input: 1.1, output: 4.4, cache_read: 0.55 },
  },
  "o4-mini": {
    name: "o4 Mini",
    limit: { context: 200000, output: 65536 },
    cost: { input: 4.0, output: 16.0, cache_read: 1.0 },
  },
  "gpt-4-turbo": {
    name: "GPT-4 Turbo",
    limit: { context: 128000, output: 4096 },
    cost: { input: 10.0, output: 30.0 },
  },
  "gpt-4": {
    name: "GPT-4",
    limit: { context: 8192, output: 4096 },
    cost: { input: 30.0, output: 60.0 },
  },
  "gpt-3.5-turbo": {
    name: "GPT-3.5 Turbo",
    limit: { context: 16385, output: 4096 },
    cost: { input: 0.5, output: 1.5 },
  },
};

export const OpenAIApiKeyPlugin: Plugin = async () => {
  return {
    config: async (config) => {
      if (!config.provider) {
        config.provider = {};
      }

      const existing = config.provider[PROVIDER_ID];
      if (!existing) {
        config.provider[PROVIDER_ID] = {
          name: PROVIDER_NAME,
          npm: PROVIDER_PACKAGE,
          models: { ...OPENAI_MODELS },
        };
        return;
      }

      if (!existing.name) {
        existing.name = PROVIDER_NAME;
      }

      if (!existing.npm) {
        existing.npm = PROVIDER_PACKAGE;
      }

      if (!existing.models) {
        existing.models = {};
      }

      for (const [modelId, modelConfig] of Object.entries(OPENAI_MODELS)) {
        if (!existing.models[modelId]) {
          existing.models[modelId] = modelConfig;
        }
      }
    },
    auth: {
      provider: PROVIDER_ID,
      loader: async (getAuth) => {
        const auth = await getAuth();
        if (!auth || auth.type !== "api") {
          return {};
        }

        return {
          apiKey: auth.key,
        };
      },
      methods: [
        {
          type: "api",
          label: "OpenAI API key",
          prompts: [
            {
              type: "text",
              key: "apiKey",
              message: "Enter your OpenAI API key",
              placeholder: "sk-...",
              validate: (value) => {
                if (!value.trim()) {
                  return "API key is required";
                }
                if (!value.trim().startsWith("sk-")) {
                  return "API key should start with 'sk-'";
                }
                return undefined;
              },
            },
          ],
          authorize: async (inputs = {}) => {
            const apiKey = (inputs.apiKey ?? "").trim();
            if (!apiKey) {
              return { type: "failed" };
            }

            return {
              type: "success",
              key: apiKey,
              provider: PROVIDER_ID,
            };
          },
        },
      ],
    },
  };
};
