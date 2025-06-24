local thisInitFile = debug.getinfo(1).source:match('@?(.*)')
local configDir = vim.fs.dirname(thisInitFile)

vim.env['XDG_CONFIG_HOME'] = configDir
vim.env['XDG_DATA_HOME'] = vim.fs.joinpath(configDir, '.xdg', 'data')
vim.env['XDG_STATE_HOME'] = vim.fs.joinpath(configDir, '.xdg', 'state')
vim.env['XDG_CACHE_HOME'] = vim.fs.joinpath(configDir, '.xdg', 'cache')
local stdPathConfig = vim.fn.stdpath('config')

vim.opt.runtimepath:prepend(stdPathConfig)
vim.opt.packpath:prepend(stdPathConfig)

local extuiExists, extui = pcall(require, 'vim._extui')
if extuiExists then
  extui.enable({enable = true, msg = {target = 'msg'}})
end

local pluginsPath = 'plugins'
vim.fn.mkdir(pluginsPath, 'p')
pluginsPath = assert(vim.uv.fs_realpath(pluginsPath))

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
  -- ['osv'] = {url = 'https://github.com/jbyuki/one-small-step-for-vimkind'},
}

for name, repo in pairs(plugins) do
  local installPath = vim.fs.joinpath(pluginsPath, name)
  gitClone(repo.url, installPath, repo.branch)
  vim.opt.runtimepath:append(installPath)
end

vim.api.nvim_create_user_command('OSVLaunch', function ()
  require('osv').launch {
    host = '127.0.0.1',
    port = 9004,
    log = '/tmp/osv.log',
  }
end, {nargs = 0})

local function init()
  vim.wo.number = true
  vim.cmd.colorscheme 'habamax'
  vim.go.termguicolors = true
  local dap = require 'dap'
  dap.defaults.fallback.switchbuf = 'useopen'
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
    }
  }

  local phpXdebugCmd = {'php', '-c', configDir}
  local phpXdebugEnv = {XDEBUG_CONFIG = 'idekey=neotest'}

  vim.api.nvim_create_user_command('PhpWithXdebug', function (opts)
    local onExit = vim.schedule_wrap(function (obj)
      vim.notify(obj.stdout)
      vim.notify(obj.stderr, vim.log.levels.WARN)
    end)

    local cmd = vim.tbl_values(phpXdebugCmd)
    table.insert(cmd, opts.fargs[1] or vim.api.nvim_buf_get_name(0))
    vim.system(cmd, {env = phpXdebugEnv}, onExit)
  end, {nargs = '?', complete = 'file'})

  vim.schedule(function ()
    vim.cmd.edit 'src/Arctgx/Foo.php'
    vim.api.nvim_win_set_cursor(0, {11, 9})
    dap.set_breakpoint()
    dap.continue()
    dap.listeners.after['event_initialized']['arctgx'] = function (_session, _body)
      vim.cmd.PhpWithXdebug({args = {'bin/test.php'}})
      vim.cmd.DapToggleRepl()
      vim.cmd.wincmd('w')
      vim.cmd.startinsert()
    end
  end)
end

vim.api.nvim_create_autocmd('UIEnter', {
  callback = init,
})
