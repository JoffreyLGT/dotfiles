-- Extra netcoredbg launch configurations for C# projects.
-- The adapter itself comes from the lang.dotnet extra; this only adds
-- configurations that build first and locate the dll automatically.
--
-- `cwd` must be the output directory, not the workspace root: the generic host
-- resolves its content root from the current directory, so appsettings.*.json
-- would otherwise not be found and configuration would come up empty.

-- Rank candidates so the startup project wins over test projects, whatever
-- order the glob happens to return them in.
local function score(csproj)
  local text = table.concat(vim.fn.readfile(csproj), "\n")
  local n = 0
  if text:match("Microsoft%.NET%.Sdk%.Web") or text:match("<OutputType>%s*Exe") then
    n = n + 2
  end
  if text:match("Microsoft%.NET%.Test%.Sdk") or text:match("<IsTestProject>%s*true") then
    n = n - 5
  end
  return n
end

local function project_dll()
  local root = vim.fn.getcwd()
  local candidates = vim.fn.glob(root .. "/*/*.csproj", false, true)
  vim.list_extend(candidates, vim.fn.glob(root .. "/*.csproj", false, true))
  table.sort(candidates, function(a, b)
    return score(a) > score(b)
  end)
  local csproj = candidates[1]
  if not csproj then
    return vim.fn.input("Path to dll: ", root .. "/", "file")
  end
  local dir = vim.fn.fnamemodify(csproj, ":h")
  local name = vim.fn.fnamemodify(csproj, ":t:r")
  local dll = vim.fn.glob(dir .. "/bin/Debug/*/" .. name .. ".dll", false, true)[1]
  return dll or vim.fn.input("Path to dll: ", dir .. "/", "file")
end

-- --no-restore keeps the launch fast and works offline; this repo's private
-- Azure Artifacts feed 401s on an implicit restore. Run `dotnet restore`
-- by hand after changing PackageReferences.
local function build()
  vim.notify("dotnet build...", vim.log.levels.INFO)
  local out = vim.fn.system({ "dotnet", "build", "-c", "Debug", "--no-restore" })
  if vim.v.shell_error ~= 0 then
    vim.notify(out, vim.log.levels.ERROR)
    error("dotnet build failed")
  end
end

-- nvim-dap evaluates each function-valued config key in an unspecified order,
-- so `program` and `cwd` share one memoized resolution instead of each doing
-- their own build/glob. Cleared once the session is under way.
local resolved
local function ensure_built()
  if not resolved then
    build()
    resolved = project_dll()
  end
  return resolved
end

local picked
local function pick_dll()
  if not picked then
    picked = vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
  end
  return picked
end

return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      for _, event in ipairs({ "event_initialized", "event_terminated", "event_exited" }) do
        dap.listeners.after[event]["dotnet-dap-reset"] = function()
          resolved, picked = nil, nil
        end
      end

      for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
        dap.configurations[lang] = {
          {
            type = "netcoredbg",
            name = "Build & launch project",
            request = "launch",
            program = ensure_built,
            cwd = function()
              return vim.fn.fnamemodify(ensure_built(), ":h")
            end,
            env = {
              ASPNETCORE_ENVIRONMENT = "Development",
              DOTNET_ENVIRONMENT = "Development",
            },
            console = "integratedTerminal",
          },
          {
            type = "netcoredbg",
            name = "Attach to process",
            request = "attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "netcoredbg",
            name = "Launch (pick dll)",
            request = "launch",
            program = pick_dll,
            cwd = function()
              return vim.fn.fnamemodify(pick_dll(), ":h")
            end,
          },
        }
      end
    end,
  },
}
