#!/bin/bash

# Script to add JavaFX template command to Neovim config

CONFIG_FILE="$HOME/.config/nvim/lua/config/keymaps.lua"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Check if JavaFX command already exists
if grep -q "JavaFX.*template" "$CONFIG_FILE"; then
    echo "JavaFX template command already exists in your config!"
    exit 0
fi

# Create backup
cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo "Backup created"

# Add the JavaFX template command
cat >> "$CONFIG_FILE" << 'EOF'

-- JavaFX Template Command
-- Usage: Open a new .java file and type :JavaFX to insert the template
vim.api.nvim_create_user_command("JavaFX", function()
  local filename = vim.fn.expand("%:t:r")
  local lines = {
    "import javafx.application.Application;",
    "import javafx.scene.Scene;",
    "import javafx.scene.control.Label;",
    "import javafx.scene.layout.StackPane;",
    "import javafx.stage.Stage;",
    "",
    "public class " .. filename .. " extends Application {",
    "    @Override",
    "    public void start(Stage primaryStage) {",
        "Label label = new Label(\"Hello JavaFX!\");",
        "        ",
        "        StackPane root = new StackPane();",
        "        root.getChildren().add(label);",
        "        ",
        "        Scene scene = new Scene(root, 400, 300);",
        "        primaryStage.setTitle(\"" .. filename .. "\");",
        "        primaryStage.setScene(scene);",
        "        primaryStage.show();",
    "    }",
    "    ",
    "    public static void main(String[] args) {",
        "        launch(args);",
    "    }",
    "}",
  }
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  -- Position cursor inside start method
  vim.api.nvim_win_set_cursor(0, { 10, 8 })
end, { desc = "Insert JavaFX template" })

-- Keybinding for JavaFX template (leader + fx)
vim.keymap.set("n", "<leader>fx", ":JavaFX<CR>", { desc = "Insert JavaFX template" })
EOF

echo "✅ JavaFX template command added successfully!"
echo ""
echo "How to use:"
echo "1. Open Neovim with a new Java file: nvim J205_2.java"
echo "2. Type :JavaFX (or press <leader>fx) to insert the JavaFX template"
echo ""
echo "Restart Neovim or run :source $CONFIG_FILE to apply changes"