# Descritpion

This plugin is a Neovim plugin that allows you to use the DeepSeek API to do do code completion in a Neovim buffer.

DeepSeek is not flat cost, it is pay-as-you-go, so completions are manually triggered by the user, not as-you-type.

# Context sending

The plugins sends the content **all** the open buffers as context to the DeepSeek API.

For example, if you open NeoVim with `nvim **/*.lua *.lua` and you ask DeepSeek to complete your file, 
it will send the content of `**/*.lua` and `*.lua` to the DeepSeek API in a multi-turn chat and then it will ask DeepSeek to complete the current buffer.

This will optimize the completions, but it will also send the content of all the files in your project to the DeepSeek API.

Be careful with this, as:

- It can be expensive if you have a lot of open buffers.
- Token calculation is **not done** before sending the context, so it the API might refuse you request if you exceed the token limit.

# Installation

Install the plugin with your favorite package manager:

```lua
use 'rakotomandimby/rktmb-deepseek-complete.nvim'
```

```lua
{
    "rakotomandimby/rktmb-deepseek-complete.nvim"
}
```

# Configuration

Users can customize the key mappings by setting `vim.g.rktmb_deepseek_complete_opts` in the configuration.  

As of writing, the following configuration options are available:

- `deepseek_api_key`: You can get it from [DeepSeek](https://platform.deepseek.com/api_keys). Defaults to the value of the `DEEPSEEK_API_KEY` environment variable.
- `suggest_keymap`: The keymap to trigger completions. Defaults to `<M-ESC>`.
- `accept_all_keymap`: The keymap to accept all completions. Defaults to `<M-PageDown>`.
- `acceptp_line_keymap`: The keymap to accept the first line of the completion. Defaults to `<M-Down>`.

To change the **suggest** keymap to `<C-j>`, set the following to a lua file that is going to be read after the installation:

```lua
vim.g.rktmb_deepseek_complete_opts = {
  deepseek_api_key = "YOUR_DEEPSEEK_API_KEY"
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

# Usage

- Enter INSERT mode
- Type your code in the current buffer (it is better if you finish a sentence)
- Issue `<M-ESC>` to trigger the completion
- The completion will be inserted in **below** the current line

# Next features

- [ ] [Add the "finish the sentence" feature (complete the current line)](https://github.com/rakotomandimby/deepseek-complete/issues/1)
- [ ] [Improve the "accept line" user experience](https://github.com/rakotomandimby/deepseek-complete/issues/2)
- [ ] [Add the "complete as-you-type" feature (heavy for the API!)](https://github.com/rakotomandimby/deepseek-complete/issues/3)

If you have any ideas, feel free to open an issue or PR!
