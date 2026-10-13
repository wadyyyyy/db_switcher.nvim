# db_switcher.nvim

Choose and switch between `vim-dadbod` connections by name with [Telescope](https://github.com/nvim-telescope/telescope.nvim).

`db_switcher.nvim` loads a user-provided Lua module containing database URLs,
publishes the connections as `vim.g.dbs` for `vim-dadbod-ui`, and sets the
selected URL as `vim.g.db` for regular Dadbod commands.

## Requirements

- Neovim `>= 0.11.7`, built with LuaJIT
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim), installed by Telescope

The plugin does not require `vim-dadbod` or `vim-dadbod-ui` to load, but those
plugins consume `vim.g.db` and `vim.g.dbs` respectively.

## Installation

### lazy.nvim

```lua
{
  "wadyyyyy/db_switcher.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    source = "config.private_dbs",
    default = "local_db",
  },
}
```

`opts` is optional; the defaults are shown below.

### vim.pack

Neovim `>= 0.12` includes the native `vim.pack` API:

```lua
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/wadyyyyy/db_switcher.nvim" },
})

require("db_switcher").setup({
  source = "config.private_dbs",
  default = "local_db",
})
```

Configure Telescope as usual if you need custom Telescope behavior.

## Configuration

The source module must return a non-empty table mapping connection names to
Dadbod URLs:

```lua
-- lua/config/private_dbs.lua
return {
  local_db = "postgres://user:password@localhost:5432/app",
  staging = "postgres://user:password@staging.example.com:5432/app",
}
```

Keep this module out of version control. A project-local `.lazy.lua` or an
ignored `private_dbs.lua` is suitable for secrets. The plugin displays only
the connection names; URLs are not shown in the picker, notifications, or
validation errors.

All setup options:

```lua
require("db_switcher").setup({
  source = "config.private_dbs",
  default = "local_db",
  command = "DBS",
  reload_command = "DBSReload",
  picker = {
    layout_strategy = "center",
    layout_config = {
      width = 0.35,
      height = 0.25,
      prompt_position = "top",
    },
    previewer = false,
  },
})
```

| Option | Default | Description |
| --- | --- | --- |
| `source` | `"config.private_dbs"` | Lua module returning the connection table |
| `default` | `nil` | Name assigned to `vim.g.db` during setup |
| `command` | `"DBS"` | Command that opens the connection picker |
| `reload_command` | `"DBSReload"` | Command that reloads the source module |
| `picker` | compact center layout | Telescope picker options |

`default` must match a key in the source table. If it does not, setup reports
an error instead of silently selecting another connection.

## Usage

Run the configured picker command:

```vim
:DBS
```

Select a connection by name. The plugin then sets:

```lua
vim.g.db_name -- selected connection name
vim.g.db      -- selected Dadbod URL
```

It also keeps the complete table in `vim.g.dbs` for `vim-dadbod-ui`.

After changing the source module, reload it with:

```vim
:DBSReload
```

Then use the standard Dadbod commands, for example:

```vim
:%DB
:'<,'>DB
```

The plugin only selects and exposes connections. Query execution, database
drivers, DBUI behavior, and SQL completion are provided by the Dadbod plugins.

## Security

Never commit database URLs containing credentials. Use an ignored module,
environment variables, or another secret-management mechanism to provide the
source table. This plugin does not mask or transform the URLs; it passes them
to Dadbod through `vim.g.db`.

## License

MIT. See [LICENSE](LICENSE).
