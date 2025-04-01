# session.nvim

A small session plugin for neovim

# Install

- Lazy.nvim

```lua
require('lazy').setup({
    {'AgatZan/session.nvim', cmd = { 'SessionSave', 'SessionDelete', 'SessionLoad'},
      opts = {} --config
    }
})
```

- packer.nvim

```lua
use({'AgatZan/session.nvim', cmd = { 'SessionSave', 'SessionDelete', 'SessionLoad'},
    config = function() require('session').setup({}) end
})
```

# Options

- `dir` — where session file live. Default: `stdpath(cache)/nvim/session`
- `is_autosave_on_exit` — create autocmd to save with default name at `VimLeavePre` event in `session_autosave` group. Default: `false`

# Commands

- `SessionSave name?` you can set a special name for session if not set will use default name it
  generate according cwd and time

- `SessionLoad |TAB` load a session by select from complete list

- `SessionDelete |TAB` delete a session

# LICENSE MIT
