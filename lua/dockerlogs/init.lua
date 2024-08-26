local pickers = require("telescope.pickers")
local config = require("telescope.config").values
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local log = require("plenary.log"):new()

log.level = "debug"

local M = {}

M.show_docker_logs = function(opts)
	pickers
		.new(opts, {
			finder = finders.new_async_job({
				command_generator = function()
					return { "docker", "compose", "ps", "--format", "json", "--services" }
				end,
				entry_maker = function(entry)
					local parsed = entry
					if parsed then
						return {
							display = parsed,
							ordinal = parsed,
							value = parsed,
						}
					end
				end,
			}),
			sorter = config.generic_sorter(opts),
			previewer = previewers.new_buffer_previewer({
				title = "Docker Image logs",
				define_preview = function(self, entry)
					local cmd = string.format("docker compose logs %s", entry.value)
					local handle = io.popen(cmd)
					if not handle then
						vim.api.nvim_err_writeln("Error: Could not fetch your logs")
						return
					end

					local logs = handle:read("*a")
					handle:close()
					vim.api.nvim_buf_set_lines(
						self.state.bufnr,
						0,
						0,
						true,
						vim.tbl_flatten({
							"",
							"```lua",
							vim.split(logs, "\n"),
							"```",
						})
					)

					utils.highlighter(self.state.bufnr, "markdown")
				end,
			}),
		})
		:find()
end

M.show_docker_logs()

return M
