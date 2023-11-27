local thisInitFile = debug.getinfo(1).source:match('@?(.*)')
local configDir = vim.fs.dirname(thisInitFile)

vim.env['XDG_CONFIG_HOME'] = configDir
vim.env['XDG_DATA_HOME'] = vim.fs.joinpath(configDir, '.xdg', 'data')
vim.env['XDG_STATE_HOME'] = vim.fs.joinpath(configDir, '.xdg', 'state')
vim.env['XDG_CACHE_HOME'] = vim.fs.joinpath(configDir, '.xdg', 'cache')
local stdPathConfig = vim.fn.stdpath('config')

vim.opt.runtimepath:prepend(stdPathConfig)
vim.opt.packpath:prepend(stdPathConfig)

local pluginsPath = 'plugins'
vim.fn.mkdir(pluginsPath, 'p')
pluginsPath = vim.uv.fs_realpath(pluginsPath)

local function gitClone(url, installPath, branch)
  if vim.fn.isdirectory(installPath) ~= 0 then
    return
  end

  local command = {'git', 'clone', '--', url, installPath}
  if branch then
    table.insert(command, 3, '--branch')
    table.insert(command, 4, branch)
  end
  local sysObj = vim.system(command, {}):wait()
  if sysObj.code ~= 0 then
    error(sysObj.stderr)
  end
  vim.notify(sysObj.stdout)
  vim.notify(sysObj.stderr, vim.log.levels.WARN)
end

local plugins = {
  ['nvim-dap'] = {url = 'https://github.com/mfussenegger/nvim-dap'},
  ['nvim-treesitter'] = {url = 'https://github.com/nvim-treesitter/nvim-treesitter'},
  ['nvim-dap-ui'] = {url = 'https://github.com/rcarriga/nvim-dap-ui'},
  ['nvim-dap-tab'] = {url = 'https://github.com/przepompownia/nvim-dap-tab'},
  ['osv'] = {url = 'https://github.com/jbyuki/one-small-step-for-vimkind'},
}

for name, repo in pairs(plugins) do
  local installPath = vim.fs.joinpath(pluginsPath, name)
  gitClone(repo.url, installPath, repo.branch)
  vim.opt.runtimepath:append(installPath)
end

local function init()
  vim.cmd.colorscheme 'habamax'
  vim.go.termguicolors = true
  local dap = require 'dap'
  dap.defaults.fallback.switchbuf = 'uselast'
  dap.set_log_level('TRACE')
  dap.adapters.php = {
    type = 'executable',
    command = vim.uv.cwd() .. '/bin/dap-adapter-utils',
    args = {'run', 'vscode-php-debug', 'phpDebug'}
  }

  dap.configurations.php = {
    {
      log = true,
      type = 'php',
      request = 'launch',
      name = 'Listen for XDebug',
      port = 9003,
      stopOnEntry = false,
      xdebugSettings = {
        max_children = 512,
        max_data = 1024,
        max_depth = 4,
      },
      breakpoints = {
        exception = {
          Notice = false,
          Warning = false,
          Error = false,
          Exception = false,
          ['*'] = false,
        },
      },
    }
  }

  require('nvim-treesitter.configs').setup {
    ensure_installed = {'php'},
    highlight = {
      enable = true,
    },
  }
  local phpXdebugCmd = {
    'php',
    '-dzend_extension=xdebug.so',
    'vendor/bin/phpunit',
  }
  local phpXdebugEnv = {XDEBUG_CONFIG = 'idekey=neotest'}

  local dapui = require('dapui')
  dapui.setup({

  })
  require('dap-tab').setup()

  vim.api.nvim_create_user_command('OSVLaunch', function ()
    require('osv').launch {
      host = '127.0.0.1',
      port = 9004,
      log = '/tmp/osv.log',
    }
  end, {nargs = 0})

  vim.api.nvim_create_user_command('PhpUnitWithXdebug', function (opts)
    local onExit = vim.schedule_wrap(function (obj)
      vim.notify(obj.stdout)
      vim.notify(obj.stderr, vim.log.levels.WARN)
    end)

    local phpunit = vim.tbl_values(phpXdebugCmd)
    table.insert(phpunit, opts.fargs[1] or vim.api.nvim_buf_get_name(0))
    vim.system(phpunit, {env = phpXdebugEnv}, onExit)
  end, {nargs = '?', complete = 'file'})

  vim.keymap.set('n', '<Esc>', vim.cmd.fclose)
  vim.keymap.set({'n'}, ',dr', dap.continue, {})
  vim.keymap.set({'n'}, ',ds', dap.step_over, {})
  vim.keymap.set({'n'}, ',dc', dap.close, {})
  vim.keymap.set({'n'}, ',dk', dap.up, {})
  vim.keymap.set({'n'}, ',dj', dap.down, {})
  vim.keymap.set({'n'}, ',dg', dapui.toggle, {})
  vim.keymap.set({'n'}, ',de', function ()
    require'dap.ui.widgets'.hover(vim.fn.expand('<cWORD>'))
  end, {})

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'php',
    callback = function ()
      function ShowListeningIndicator()
        local indicator = '%#DiagnosticError#⛧ %#StatusLine# [Listening...]'
        return dap.session() and indicator or '%#DiagnosticInfo#☠%#StatusLine# [No debug session]'
      end
      vim.opt_local.statusline = '%{%v:lua.ShowListeningIndicator()%} %f'
    end
  })

  vim.schedule(function ()
    vim.cmd.edit 'tests/Arctgx/DapStrategy/TrivialTest.php'
    vim.api.nvim_win_set_cursor(0, {11, 9})
    dap.set_breakpoint()
    dap.continue()
    dap.listeners.after['event_initialized']['arctgx'] = function (_session, _body)
      vim.cmd.PhpUnitWithXdebug()
    end
  end)
end

vim.api.nvim_create_autocmd('UIEnter', {
  callback = init,
})
