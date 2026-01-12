return {
  "laytan/cloak.nvim",
  config = function()
    -- Helper function to create case-insensitive patterns for sensitive keywords
    local function make_pattern(keyword, separator)
      separator = separator or "="
      -- Convert keyword to case-insensitive character class pattern
      local pattern_parts = {}
      for i = 1, #keyword do
        local c = keyword:sub(i, i)
        local lower = c:lower()
        local upper = c:upper()
        if lower ~= upper then
          table.insert(pattern_parts, "[" .. lower .. upper .. "]")
        elseif c == "_" then
          -- Allow underscore or hyphen
          table.insert(pattern_parts, "[_%-]")
        else
          table.insert(pattern_parts, c)
        end
      end
      local pattern = table.concat(pattern_parts)
      -- Match optional underscores/hyphens, whitespace, separator, whitespace, and capture until end
      -- Also matches if there are quotes around the value
      return {
        "(" .. pattern .. "%s*" .. separator .. "%s*['\"]?).+",
        replace = "%1"
      }
    end

    -- Comprehensive list of sensitive keywords to cloak
    local sensitive_keywords = {
      "api_key",
      "api_secret",
      "apikey",
      "apisecret",
      "access_token",
      "access_secret",
      "accesstoken",
      "accesssecret",
      "bearer_token",
      "bearer",
      "auth_token",
      "authtoken",
      "client_id",
      "client_secret",
      "clientid",
      "clientsecret",
      "oauth_token",
      "oauth_secret",
      "oauth2_token",
      "oauth2_secret",
      "password",
      "passwd",
      "pass",
      "secret",
      "private_key",
      "privatekey",
      "token",
      "credential",
      "credentials",
      "auth",
      "session_secret",
      "jwt_secret",
      "encryption_key",
      "encryptionkey",
    }

    -- Generate patterns for = separator (TOML, INI, ENV)
    local equals_patterns = {}
    for _, keyword in ipairs(sensitive_keywords) do
      table.insert(equals_patterns, make_pattern(keyword, "="))
    end

    -- Generate patterns for : separator (YAML)
    local colon_patterns = {}
    for _, keyword in ipairs(sensitive_keywords) do
      table.insert(colon_patterns, make_pattern(keyword, ":"))
    end

    -- Generate patterns for -- flags (command-line style in .conf files)
    local flag_patterns = {}
    for _, keyword in ipairs(sensitive_keywords) do
      table.insert(flag_patterns, {
        "(%-%-" .. keyword:gsub("_", "%-") .. "=).+",
        replace = "%1"
      })
    end

    require("cloak").setup({
      enabled = true,
      cloak_character = "•",
      highlight_group = "Comment",
      try_all_patterns = true,
      cloak_telescope = true,
      patterns = {
        {
          -- Environment files - cloak all key=value pairs
          file_pattern = {
            ".env*",
            ".dev.vars",
          },
          cloak_pattern = "=.+",
        },
        {
          -- TOML files - cloak only sensitive keywords
          file_pattern = {
            "*.toml",
            "wrangler.toml",
            "config.toml",
          },
          cloak_pattern = equals_patterns,
        },
        {
          -- YAML files - cloak only sensitive keywords with colon separator
          file_pattern = {
            "*.yaml",
            "*.yml",
          },
          cloak_pattern = colon_patterns,
        },
        {
          -- Config files - cloak sensitive keywords with = or -- flag format
          file_pattern = {
            "*.conf",
            "*.cfg",
            "*.ini",
          },
          cloak_pattern = vim.list_extend(vim.deepcopy(equals_patterns), flag_patterns),
        },
        {
          -- Files with sensitive names - cloak all key=value or key: value pairs
          file_pattern = {
            "*secret*",
            "*token*",
            "*key*",
            "*credential*",
            "*password*",
            "*auth*",
          },
          cloak_pattern = { "=.+", ":.+" },
        },
      },
    })
  end,
}
