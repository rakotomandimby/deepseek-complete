# Descritpion

This plugin is a Neovim plugin that allows you to use the DeepSeek API to do do code completion in a Neovim buffer.

DeepSeek is not flat cost, so completions are manually triggered by the user, not as-you-type.

# Installation

Install the plugin with your favorite package manager:

```lua
use 'mihamina/rktmb-deepseek-complete.nvim'
```

```lua
{
    "mihamina/rktmb-deepseek-complete.nvim"
}
```


# Configuration

Users can customize the key mappings by setting `vim.g.rktmb_deepseek_complete_opts` in the configuration.  

As of writing, the following configuration options are available:

- `suggest_keymap`: The keymap to trigger completions. Defaults to `<M-ESC>`.
- `accept_all_keymap`: The keymap to accept all completions. Defaults to `<M-PageDown>`.
- `acceptp_line_keymap`: The keymap to accept the first line of the completion. Defaults to `<M-Down>`.

To change the **suggest** keymap to `<C-j>`, set the following to a lua file that is going to be read after the installation:

```lua
vim.g.rktmb_deepseek_complete_opts = {
  suggest_keymap = "<C-j>",
}
```

Or to disable a keymap entirely (I dont now why would you do that, but you can):

```lua
vim.g.rktmb_deepseek_complete_opts = {
  accept_all_keymap = "",
  acceptp_line_keymap=""
}
```
