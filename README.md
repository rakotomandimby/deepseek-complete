# What is this?

This plugin is a Neovim plugin that allows you to use the DeepSeek API to do do code completion in a Neovim buffer.

# Configuration

Users can customize the key mappings by setting `vim.g.rktmb_deepseek_complete_opts` in the configuration.  

For example, to change the **suggest** keymap to `<C-j>`, set the following to their `init.lua`:

```lua
vim.g.rktmb_deepseek_complete_opts = {
  suggest_keymap = "<C-j>",
}
```

Or to disable a keymap entirely:

```lua
vim.g.rktmb_deepseek_complete_opts = {
  accept_all_keymap = "",
  acceptp_line_keymap=""
}
```
