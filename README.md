# db-picker.nvim

Choose a `vim-dadbod` connection by name with Telescope.

The plugin loads a user-provided Lua module, exposes it as `vim.g.dbs` for
`vim-dadbod-ui`, and sets the selected URL as `vim.g.db` for regular Dadbod
commands such as `:%DB`.

## Setup

```lua
{
  "your-name/db-picker.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
    source = "config.private_dbs",
    default = "local_db",
  },
}
```

`default` is optional. When set, the matching connection is assigned to
`vim.g.db` during startup, so `:%DB` can be used immediately.

The source module must return a table mapping names to URLs:

```lua
return {
  local_db = "postgres://user:password@localhost:5432/app",
  staging = "postgres://user:password@staging.example.com:5432/app",
}
```

Keep the source module outside version control. The plugin only displays the
connection names; URLs are not shown in the picker or notifications.

## Usage

Run `:DBPick`, choose a connection, and then use:

```vim
:%DB
:'<,'>DB
```

The selected URL is available as `vim.g.db`, and all configured connections
remain available to `vim-dadbod-ui` through `vim.g.dbs`.

Run `:DBPickReload` after changing the source module.

The picker uses a compact centered layout by default. You can override its
Telescope options:

```lua
opts = {
  source = "config.private_dbs",
  picker = {
    layout_strategy = "center",
    layout_config = { width = 0.3, height = 0.2 },
  },
}
```

## LazyVim development setup

```lua
{
  "your-name/db-picker.nvim",
  dev = true,
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
    source = "config.private_dbs",
    default = "local_db",
  },
}
```
